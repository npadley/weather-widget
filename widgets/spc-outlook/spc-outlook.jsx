// SPC Day 1 Convective Outlook Widget for Übersicht
// Displays the latest SPC Day 1 outlook map with selectable type and refresh rate.
//
// Install: copy this folder to ~/Library/Application Support/Übersicht/widgets/

import { React } from 'uebersicht'

const BASE_URL = 'https://www.spc.noaa.gov/products/outlook/'

const REFRESH_OPTIONS = [
  { label: '5 min',  value: '5',   ms: 5 * 60 * 1000 },
  { label: '15 min', value: '15',  ms: 15 * 60 * 1000 },
  { label: '30 min', value: '30',  ms: 30 * 60 * 1000 },
  { label: '1 hr',   value: '60',  ms: 60 * 60 * 1000 },
  { label: '6 hr',   value: '360', ms: 6 * 60 * 60 * 1000 },
]

const TABS = [
  { id: 'cat',  label: 'Categorical' },
  { id: 'torn', label: 'Tornado' },
  { id: 'wind', label: 'Wind' },
  { id: 'hail', label: 'Hail' },
]

// Read stored refresh preference (evaluated at module load, controls Übersicht scheduling)
const getStoredRefresh = () => {
  try {
    return localStorage.getItem('spc-outlook-refresh') || '15'
  } catch (e) {
    return '15'
  }
}

const storedRefreshKey = getStoredRefresh()
const storedRefreshMs = REFRESH_OPTIONS.find(r => r.value === storedRefreshKey)?.ms ?? 15 * 60 * 1000

// Übersicht will re-run this widget on this schedule.
// Changing the refresh selector updates localStorage; the new value takes effect
// on the next Übersicht reload cycle.
export const refreshFrequency = storedRefreshMs

// Shell command: fetch the SPC Day 1 outlook page, extract the current issuance
// time suffix (e.g. "2000" for the 20:00 UTC issuance), and return JSON.
export const command = `
  set -e
  PAGE=$(curl -s --max-time 15 "https://www.spc.noaa.gov/products/outlook/day1otlk.html" 2>/dev/null)
  if [ -z "$PAGE" ]; then
    echo '{"error":"Network error: could not reach spc.noaa.gov"}'
    exit 0
  fi
  SUFFIX=$(echo "$PAGE" | grep -oE "otlk_[0-9]+" | head -1 | grep -oE "[0-9]+")
  if [ -z "$SUFFIX" ]; then
    echo '{"error":"Could not parse issuance time from SPC page"}'
  else
    echo "{\\"suffix\\":\\"$SUFFIX\\"}"
  fi
`

export const initialState = {
  suffix: null,
  lastUpdated: null,
  fetchError: null,
}

export const updateState = (event, previousState) => {
  if (event.error) {
    return {
      ...previousState,
      fetchError: String(event.error),
      lastAttempt: Date.now(),
    }
  }
  try {
    const parsed = JSON.parse(event.output.trim())
    if (parsed.error || !parsed.suffix) {
      return {
        ...previousState,
        fetchError: parsed.error || 'Unknown parse error',
        lastAttempt: Date.now(),
      }
    }
    return {
      ...previousState,
      suffix: parsed.suffix,
      lastUpdated: Date.now(),
      fetchError: null,
    }
  } catch (e) {
    return {
      ...previousState,
      fetchError: `Parse error: ${event.output}`,
      lastAttempt: Date.now(),
    }
  }
}

// --- Helpers ---

const getImageUrl = (suffix, tab, ts) => {
  if (!suffix) return null
  const base = `${BASE_URL}day1`
  const bust = `?t=${ts}`
  switch (tab) {
    case 'cat':  return `${base}otlk_${suffix}.png${bust}`
    case 'torn': return `${base}probotlk_${suffix}_torn.png${bust}`
    case 'wind': return `${base}probotlk_${suffix}_wind.png${bust}`
    case 'hail': return `${base}probotlk_${suffix}_hail.png${bust}`
    default:     return null
  }
}

const formatTime = (ms) => {
  if (!ms) return '--:--'
  return new Date(ms).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

// --- Styles ---

const S = {
  widget: {
    position: 'fixed',
    top: '20px',
    right: '20px',
    width: '520px',
    background: 'rgba(8, 12, 22, 0.90)',
    backdropFilter: 'blur(16px)',
    WebkitBackdropFilter: 'blur(16px)',
    borderRadius: '14px',
    border: '1px solid rgba(255, 255, 255, 0.10)',
    fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif',
    color: '#ffffff',
    overflow: 'hidden',
    boxShadow: '0 12px 40px rgba(0, 0, 0, 0.70)',
    userSelect: 'none',
  },
  header: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: '11px 14px 9px',
    borderBottom: '1px solid rgba(255, 255, 255, 0.07)',
  },
  titleBlock: {
    display: 'flex',
    flexDirection: 'column',
    gap: '1px',
  },
  title: {
    fontSize: '13px',
    fontWeight: '600',
    color: '#efefef',
    letterSpacing: '0.2px',
  },
  issuance: {
    fontSize: '10px',
    color: '#606878',
    letterSpacing: '0.2px',
  },
  spcLink: {
    fontSize: '10px',
    color: '#4a9eff',
    textDecoration: 'none',
    opacity: 0.8,
  },
  tabs: {
    display: 'flex',
    gap: '3px',
    padding: '8px 12px 6px',
    background: 'rgba(255, 255, 255, 0.025)',
    borderBottom: '1px solid rgba(255, 255, 255, 0.05)',
  },
  tab: (active) => ({
    flex: 1,
    padding: '5px 4px',
    textAlign: 'center',
    fontSize: '11px',
    fontWeight: active ? '600' : '400',
    color: active ? '#ffffff' : 'rgba(255, 255, 255, 0.42)',
    background: active ? 'rgba(74, 158, 255, 0.22)' : 'transparent',
    border: active ? '1px solid rgba(74, 158, 255, 0.35)' : '1px solid transparent',
    borderRadius: '6px',
    cursor: 'pointer',
    outline: 'none',
    transition: 'all 0.12s ease',
    letterSpacing: '0.2px',
  }),
  imageWrap: {
    position: 'relative',
    width: '100%',
    height: '358px',
    background: 'rgba(0, 0, 0, 0.35)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  image: {
    width: '100%',
    height: '100%',
    objectFit: 'contain',
    display: 'block',
  },
  statusOverlay: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    gap: '6px',
    padding: '20px',
    textAlign: 'center',
  },
  errorIcon: {
    fontSize: '22px',
  },
  errorText: {
    fontSize: '12px',
    color: '#f06060',
    fontWeight: '500',
  },
  errorDetail: {
    fontSize: '10px',
    color: '#4a4f58',
    maxWidth: '300px',
    lineHeight: '1.4',
  },
  loadingText: {
    fontSize: '12px',
    color: '#55606a',
  },
  footer: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: '7px 13px 9px',
    borderTop: '1px solid rgba(255, 255, 255, 0.07)',
  },
  footerLeft: {
    fontSize: '10px',
    color: '#4a5260',
    display: 'flex',
    alignItems: 'center',
    gap: '4px',
  },
  footerRight: {
    display: 'flex',
    alignItems: 'center',
    gap: '6px',
  },
  refreshLabel: {
    fontSize: '10px',
    color: '#4a5260',
  },
  refreshSelect: {
    background: 'rgba(255, 255, 255, 0.07)',
    border: '1px solid rgba(255, 255, 255, 0.12)',
    borderRadius: '5px',
    color: '#8a96a8',
    fontSize: '10px',
    padding: '3px 7px 3px 6px',
    outline: 'none',
    cursor: 'pointer',
    appearance: 'none',
    WebkitAppearance: 'none',
  },
}

// --- Widget Component ---

export const render = ({ suffix, lastUpdated, fetchError, lastAttempt }) => {
  const [activeTab, setActiveTab] = React.useState('cat')
  const [refreshRate, setRefreshRate] = React.useState(getStoredRefresh)
  const [imgLoaded, setImgLoaded] = React.useState(false)
  const [imgError, setImgError] = React.useState(false)

  const lastTime = lastUpdated || lastAttempt
  const imgUrl = suffix ? getImageUrl(suffix, activeTab, lastUpdated) : null

  // Reset image state when tab or URL changes
  React.useEffect(() => {
    setImgLoaded(false)
    setImgError(false)
  }, [imgUrl])

  const handleRefreshChange = (e) => {
    const val = e.target.value
    setRefreshRate(val)
    try {
      localStorage.setItem('spc-outlook-refresh', val)
    } catch (_) {}
  }

  const issuanceLabel = suffix
    ? `Issued ${suffix.slice(0, 2)}:${suffix.slice(2)} UTC`
    : 'Fetching issuance time…'

  const hasData = Boolean(suffix)
  const showError = !hasData && Boolean(fetchError)
  const showLoading = !hasData && !fetchError

  return (
    <div style={S.widget}>

      {/* Header */}
      <div style={S.header}>
        <div style={S.titleBlock}>
          <span style={S.title}>SPC Day 1 Convective Outlook</span>
          <span style={S.issuance}>{issuanceLabel}</span>
        </div>
        <a
          href="https://www.spc.noaa.gov/products/outlook/day1otlk.html"
          style={S.spcLink}
        >
          spc.noaa.gov ↗
        </a>
      </div>

      {/* Outlook type tabs */}
      <div style={S.tabs}>
        {TABS.map(t => (
          <button
            key={t.id}
            style={S.tab(activeTab === t.id)}
            onClick={() => setActiveTab(t.id)}
          >
            {t.label}
          </button>
        ))}
      </div>

      {/* Map image */}
      <div style={S.imageWrap}>
        {showError && (
          <div style={S.statusOverlay}>
            <span style={S.errorIcon}>⚠</span>
            <span style={S.errorText}>Could not load outlook</span>
            <span style={S.errorDetail}>{fetchError}</span>
          </div>
        )}

        {showLoading && (
          <div style={S.statusOverlay}>
            <span style={S.loadingText}>Loading outlook…</span>
          </div>
        )}

        {imgUrl && (
          <>
            {imgError ? (
              <div style={S.statusOverlay}>
                <span style={S.errorIcon}>⚠</span>
                <span style={S.errorText}>Image unavailable</span>
                <span style={S.errorDetail}>
                  Could not load {TABS.find(t => t.id === activeTab)?.label} map.
                  SPC may still be generating this issuance.
                </span>
              </div>
            ) : (
              <img
                key={imgUrl}
                src={imgUrl}
                style={{ ...S.image, opacity: imgLoaded ? 1 : 0, transition: 'opacity 0.2s ease' }}
                onLoad={() => setImgLoaded(true)}
                onError={() => setImgError(true)}
              />
            )}
            {!imgLoaded && !imgError && (
              <div style={{ ...S.statusOverlay, position: 'absolute' }}>
                <span style={S.loadingText}>Loading map…</span>
              </div>
            )}
          </>
        )}
      </div>

      {/* Footer */}
      <div style={S.footer}>
        <div style={S.footerLeft}>
          {fetchError && suffix && (
            <span style={{ color: '#c08020' }}>⚠ stale · </span>
          )}
          <span>Updated {formatTime(lastTime)}</span>
        </div>

        <div style={S.footerRight}>
          <span style={S.refreshLabel}>Refresh:</span>
          <select
            style={S.refreshSelect}
            value={refreshRate}
            onChange={handleRefreshChange}
          >
            {REFRESH_OPTIONS.map(o => (
              <option key={o.value} value={o.value}>{o.label}</option>
            ))}
          </select>
        </div>
      </div>

    </div>
  )
}
