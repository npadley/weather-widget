import SwiftUI

struct ContentView: View {
    @State private var viewModel = OutlookViewModel()
    @State private var hoveredDay: OutlookDay?
    @State private var hoveredType: OutlookType?

    var body: some View {
        VStack(spacing: 0) {
            headerView
            dayPicker
            tabBar
            mapView
            footerView
        }
        // No fixed width — let the window drive the size.
        // Use a shaped background so the material is confined to the rounded
        // rect and doesn't bleed into the window corners as a grey box.
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
    }

    // MARK: Header

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SPC Convective Outlook")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(viewModel.issuanceLabel)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await viewModel.fetchOutlook() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .rotationEffect(viewModel.isLoading ? .degrees(360) : .degrees(0))
                    .animation(
                        viewModel.isLoading
                            ? .linear(duration: 1).repeatForever(autoreverses: false)
                            : .default,
                        value: viewModel.isLoading
                    )
            }
            .buttonStyle(.plain)
            .help("Refresh now")
        }
        .padding(.horizontal, 14)
        .padding(.top, 11)
        .padding(.bottom, 8)
    }

    // MARK: Day picker

    @ViewBuilder
    private var dayPicker: some View {
        HStack(spacing: 0) {
            ForEach(OutlookDay.allCases, id: \.self) { day in
                let isActive  = viewModel.activeDay == day
                let isHovered = hoveredDay == day

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        viewModel.activeDay = day
                    }
                } label: {
                    Text(day.label)
                        .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    isActive  ? Color.primary.opacity(0.14) :
                                    isHovered ? Color.primary.opacity(0.07) :
                                                Color.clear
                                )
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(isActive ? Color.primary : Color.secondary)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        hoveredDay = hovering ? day : nil
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
        .background(Color.primary.opacity(0.04))
        Divider().opacity(0.3)
    }

    // MARK: Tab bar

    @ViewBuilder
    private var tabBar: some View {
        HStack(spacing: 3) {
            ForEach(viewModel.activeDay.availableTypes, id: \.self) { type in
                let isActive  = viewModel.activeType == type
                let isHovered = hoveredType == type

                Button {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        viewModel.activeType = type
                    }
                } label: {
                    Text(type.label)
                        .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    isActive  ? Color.accentColor.opacity(0.22) :
                                    isHovered ? Color.accentColor.opacity(0.10) :
                                                Color.clear
                                )
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    isActive  ? Color.accentColor.opacity(0.40) :
                                    isHovered ? Color.accentColor.opacity(0.18) :
                                                Color.clear,
                                    lineWidth: 1
                                )
                        }
                }
                .buttonStyle(.plain)
                .foregroundStyle(isActive ? Color.primary : Color.secondary)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        hoveredType = hovering ? type : nil
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.03))
        Divider().opacity(0.4)
    }

    // MARK: Map image

    @ViewBuilder
    private var mapView: some View {
        ZStack {
            Color.black.opacity(0.25)

            if let url = viewModel.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        loadingIndicator("Loading map…")
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .transition(.opacity.animation(.easeIn(duration: 0.2)))
                    case .failure:
                        errorView(
                            icon: "photo.badge.exclamationmark",
                            title: "Image unavailable",
                            detail: "\(viewModel.activeType.label) map could not be loaded. SPC may still be generating this issuance."
                        )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else if let error = viewModel.errorMessage {
                errorView(
                    icon: "wifi.exclamationmark",
                    title: "Could not reach SPC",
                    detail: error
                )
            } else {
                loadingIndicator("Loading outlook…")
            }
        }
        // Flexible height — grows when the window is resized.
        .frame(minHeight: 200, maxHeight: .infinity)
        Divider().opacity(0.4)
    }

    private func loadingIndicator(_ message: String) -> some View {
        VStack(spacing: 10) {
            ProgressView()
                .controlSize(.regular)
                .tint(.secondary)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func errorView(icon: String, title: String, detail: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .padding(20)
    }

    // MARK: Footer

    private var footerView: some View {
        HStack {
            Group {
                if viewModel.isLoading {
                    Label("Refreshing…", systemImage: "arrow.clockwise")
                } else if viewModel.errorMessage != nil && viewModel.suffix != nil {
                    Label("Stale data", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.yellow.opacity(0.8))
                } else {
                    Text(viewModel.lastUpdatedLabel)
                }
            }
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)

            Spacer()

            HStack(spacing: 5) {
                Text("Refresh:")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)

                Picker("Refresh interval", selection: $viewModel.refreshInterval) {
                    ForEach(RefreshInterval.allCases, id: \.self) { interval in
                        Text(interval.label).tag(interval)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .font(.system(size: 10))
                .frame(width: 72)
                .controlSize(.mini)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
    }
}
