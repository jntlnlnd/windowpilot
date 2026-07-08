import AppKit

final class SwitcherOverlay {
    static let columnCount = 5

    private let itemWidth: CGFloat = 214
    private let itemHeight: CGFloat = 140
    private let columnSpacing: CGFloat = 22
    private let rowSpacing: CGFloat = 18
    private let topPadding: CGFloat = 26
    private let bottomPadding: CGFloat = 22

    private let panel: NSPanel
    private let contentView = NSView()
    private let gridView = NSView()
    private let leftChevron = NSTextField(labelWithString: "‹")
    private let rightChevron = NSTextField(labelWithString: "›")
    private var previewCache: [String: NSImage] = [:]

    var isVisible: Bool {
        panel.isVisible
    }

    init() {
        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

        let panelView = NSView()
        panelView.wantsLayer = true
        panelView.layer?.cornerRadius = 16
        panelView.layer?.masksToBounds = true
        panelView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.78).cgColor

        contentView.translatesAutoresizingMaskIntoConstraints = false
        panelView.addSubview(contentView)

        gridView.translatesAutoresizingMaskIntoConstraints = false

        configureChevron(leftChevron)
        configureChevron(rightChevron)

        contentView.addSubview(leftChevron)
        contentView.addSubview(gridView)
        contentView.addSubview(rightChevron)

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: panelView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: panelView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: panelView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: panelView.bottomAnchor),

            leftChevron.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            leftChevron.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -12),
            leftChevron.widthAnchor.constraint(equalToConstant: 34),

            rightChevron.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            rightChevron.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -12),
            rightChevron.widthAnchor.constraint(equalToConstant: 34),

            gridView.leadingAnchor.constraint(equalTo: leftChevron.trailingAnchor, constant: 18),
            gridView.trailingAnchor.constraint(equalTo: rightChevron.leadingAnchor, constant: -18),
            gridView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topPadding),
            gridView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -bottomPadding)
        ])

        panel.contentView = panelView
    }

    func show(windows: [SwitchableWindow], selectedIndex: Int) {
        previewCache.removeAll()
        update(windows: windows, selectedIndex: selectedIndex)
        panel.orderFrontRegardless()
    }

    func update(windows: [SwitchableWindow], selectedIndex: Int) {
        rebuildItems(windows: windows, selectedIndex: selectedIndex)

        let visibleFrame = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 900, height: 700)
        let layout = visibleLayout(windows: windows, selectedIndex: selectedIndex)
        let preferredWidth = CGFloat(layout.columnCount) * itemWidth
            + CGFloat(max(layout.columnCount - 1, 0)) * columnSpacing
            + 150
        let width = max(520, min(preferredWidth, visibleFrame.width - 96))
        let height = topPadding
            + CGFloat(layout.rowCount) * itemHeight
            + CGFloat(max(layout.rowCount - 1, 0)) * rowSpacing
            + bottomPadding
        let origin = CGPoint(
            x: visibleFrame.midX - width / 2,
            y: visibleFrame.midY - height / 2
        )
        panel.setFrame(CGRect(origin: origin, size: CGSize(width: width, height: height)), display: true)
    }

    func hide() {
        panel.orderOut(nil)
        previewCache.removeAll()
    }

    private func rebuildItems(windows: [SwitchableWindow], selectedIndex: Int) {
        gridView.subviews.forEach { view in
            view.removeFromSuperview()
        }

        let layout = visibleLayout(windows: windows, selectedIndex: selectedIndex)
        let items = layout.items
        for itemData in items {
            let itemView = item(for: itemData.window, selected: itemData.index == selectedIndex)
            let row = (itemData.index / Self.columnCount) - layout.startRow
            let column = itemData.index % Self.columnCount
            gridView.addSubview(itemView)

            NSLayoutConstraint.activate([
                itemView.leadingAnchor.constraint(equalTo: gridView.leadingAnchor, constant: CGFloat(column) * (itemWidth + columnSpacing)),
                itemView.topAnchor.constraint(equalTo: gridView.topAnchor, constant: CGFloat(row) * (itemHeight + rowSpacing))
            ])
        }

        leftChevron.isHidden = selectedIndex <= 0
        rightChevron.isHidden = selectedIndex >= windows.count - 1
    }

    private func visibleLayout(
        windows: [SwitchableWindow],
        selectedIndex: Int
    ) -> (items: [(index: Int, window: SwitchableWindow)], startRow: Int, rowCount: Int, columnCount: Int) {
        guard !windows.isEmpty else {
            return ([], 0, 1, 1)
        }

        let clampedSelection = min(max(selectedIndex, 0), windows.count - 1)
        let totalRows = Int(ceil(Double(windows.count) / Double(Self.columnCount)))
        let selectedRow = clampedSelection / Self.columnCount
        let visibleRowCount = min(3, totalRows)
        let startRow = min(max(selectedRow - visibleRowCount + 1, 0), max(totalRows - visibleRowCount, 0))
        let lowerBound = startRow * Self.columnCount
        let upperBound = min(lowerBound + visibleRowCount * Self.columnCount, windows.count)
        let items = Array(windows[lowerBound..<upperBound].enumerated()).map { offset, window in
            (lowerBound + offset, window)
        }
        let columnCount = windows.count > Self.columnCount ? Self.columnCount : max(windows.count, 1)
        return (items, startRow, visibleRowCount, columnCount)
    }

    private func item(for window: SwitchableWindow, selected: Bool) -> NSView {
        let item = NSView()
        item.translatesAutoresizingMaskIntoConstraints = false
        item.wantsLayer = true

        let selectionGlow = NSView()
        selectionGlow.translatesAutoresizingMaskIntoConstraints = false
        selectionGlow.wantsLayer = true
        selectionGlow.isHidden = !selected
        selectionGlow.layer?.cornerRadius = 13
        selectionGlow.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.24).cgColor
        selectionGlow.layer?.borderColor = NSColor.white.withAlphaComponent(0.46).cgColor
        selectionGlow.layer?.borderWidth = 1.5
        selectionGlow.layer?.shadowColor = NSColor.white.cgColor
        selectionGlow.layer?.shadowOpacity = 0.88
        selectionGlow.layer?.shadowRadius = 30
        selectionGlow.layer?.shadowOffset = .zero

        let previewContainer = NSView()
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.wantsLayer = true
        previewContainer.layer?.cornerRadius = 7
        previewContainer.layer?.masksToBounds = false
        previewContainer.layer?.backgroundColor = selected ? NSColor.white.withAlphaComponent(0.28).cgColor : NSColor.black.withAlphaComponent(0.50).cgColor
        previewContainer.layer?.borderColor = selected ? NSColor.white.withAlphaComponent(0.92).cgColor : NSColor.white.withAlphaComponent(0.16).cgColor
        previewContainer.layer?.borderWidth = selected ? 2 : 1
        previewContainer.layer?.shadowColor = selected ? NSColor.white.cgColor : NSColor.black.cgColor
        previewContainer.layer?.shadowOpacity = selected ? 0.70 : 0.34
        previewContainer.layer?.shadowRadius = selected ? 17 : 6
        previewContainer.layer?.shadowOffset = selected ? .zero : CGSize(width: 0, height: -2)

        let preview = NSImageView(image: previewImage(for: window))
        preview.imageScaling = .scaleProportionallyUpOrDown
        preview.translatesAutoresizingMaskIntoConstraints = false
        preview.wantsLayer = true
        preview.layer?.cornerRadius = 5
        preview.layer?.masksToBounds = true
        preview.alphaValue = selected ? 1.0 : 0.42
        previewContainer.addSubview(preview)

        let icon = NSImageView(image: appIcon(for: window))
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.wantsLayer = true
        icon.layer?.shadowColor = NSColor.black.cgColor
        icon.layer?.shadowOpacity = selected ? 0.85 : 0.55
        icon.layer?.shadowRadius = selected ? 7 : 4
        icon.layer?.shadowOffset = CGSize(width: 0, height: -1)
        icon.alphaValue = selected ? 1.0 : 0.54

        let title = NSTextField(labelWithString: displayTitle(for: window))
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = .systemFont(ofSize: selected ? 14 : 13, weight: selected ? .bold : .semibold)
        title.textColor = NSColor.white.withAlphaComponent(selected ? 1.0 : 0.50)
        title.alignment = .center
        title.lineBreakMode = .byTruncatingTail
        title.maximumNumberOfLines = 1
        title.cell?.lineBreakMode = .byTruncatingTail
        title.cell?.truncatesLastVisibleLine = true
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        title.shadow = textShadow()

        item.addSubview(selectionGlow)
        item.addSubview(previewContainer)
        item.addSubview(icon)
        item.addSubview(title)

        NSLayoutConstraint.activate([
            item.widthAnchor.constraint(equalToConstant: itemWidth),
            item.heightAnchor.constraint(equalToConstant: itemHeight),

            selectionGlow.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: -10),
            selectionGlow.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: 10),
            selectionGlow.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: -9),
            selectionGlow.bottomAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),

            previewContainer.leadingAnchor.constraint(equalTo: item.leadingAnchor),
            previewContainer.trailingAnchor.constraint(equalTo: item.trailingAnchor),
            previewContainer.topAnchor.constraint(equalTo: item.topAnchor),
            previewContainer.heightAnchor.constraint(equalToConstant: 96),

            preview.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 5),
            preview.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -5),
            preview.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 5),
            preview.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: -5),

            icon.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: 10),
            icon.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 10),
            icon.widthAnchor.constraint(equalToConstant: 42),
            icon.heightAnchor.constraint(equalToConstant: 42),

            title.leadingAnchor.constraint(equalTo: item.leadingAnchor, constant: 4),
            title.trailingAnchor.constraint(equalTo: item.trailingAnchor, constant: -4),
            title.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 11)
        ])

        return item
    }

    private func appIcon(for window: SwitchableWindow) -> NSImage {
        if let bundleURL = window.runningApplication?.bundleURL {
            return NSWorkspace.shared.icon(forFile: bundleURL.path)
        }
        return NSWorkspace.shared.icon(for: .application)
    }

    private func previewImage(for window: SwitchableWindow) -> NSImage {
        let key = previewCacheKey(for: window)
        if let cachedImage = previewCache[key] {
            return cachedImage
        }

        let image: NSImage
        if let windowID = window.cgWindowID,
           let cgImage = CGWindowListCreateImage(.null, .optionIncludingWindow, windowID, [.boundsIgnoreFraming, .bestResolution]) {
            image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        } else {
            image = fallbackPreviewImage(for: window)
        }

        previewCache[key] = image
        return image
    }

    private func fallbackPreviewImage(for window: SwitchableWindow) -> NSImage {
        let image = NSImage(size: NSSize(width: 214, height: 96))
        image.lockFocus()
        NSColor(calibratedWhite: 0.18, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 214, height: 96), xRadius: 6, yRadius: 6).fill()

        let icon = appIcon(for: window)
        icon.draw(in: NSRect(x: 83, y: 29, width: 48, height: 48), from: .zero, operation: .sourceOver, fraction: 0.9)
        image.unlockFocus()
        return image
    }

    private func previewCacheKey(for window: SwitchableWindow) -> String {
        if let cgWindowID = window.cgWindowID {
            return "cg:\(cgWindowID)"
        }

        return [
            "ax",
            "\(window.pid)",
            window.bundleIdentifier ?? "",
            window.title,
            "\(Int(window.frame.minX))",
            "\(Int(window.frame.minY))",
            "\(Int(window.frame.width))",
            "\(Int(window.frame.height))"
        ].joined(separator: ":")
    }

    private func displayTitle(for window: SwitchableWindow) -> String {
        let trimmedTitle = window.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, trimmedTitle != "-", trimmedTitle != "Untitled Window" else {
            return window.appName
        }

        let appSuffixes = [
            " - \(window.appName)",
            " — \(window.appName)",
            " – \(window.appName)"
        ]
        let titleWithoutAppSuffix = appSuffixes.reduce(trimmedTitle) { title, suffix in
            title.hasSuffix(suffix) ? String(title.dropLast(suffix.count)) : title
        }

        return titleWithoutAppSuffix.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func configureChevron(_ label: NSTextField) {
        label.font = .systemFont(ofSize: 70, weight: .medium)
        label.textColor = NSColor.white.withAlphaComponent(0.58)
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.shadow = textShadow()
    }

    private func textShadow() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.85)
        shadow.shadowBlurRadius = 4
        shadow.shadowOffset = CGSize(width: 0, height: -1)
        return shadow
    }
}
