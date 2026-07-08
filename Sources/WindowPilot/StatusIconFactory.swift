import AppKit

enum StatusIconFactory {
    static func make(active: Bool) -> NSImage {
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size)
        image.lockFocus()

        let bounds = NSRect(origin: .zero, size: size)
        NSColor.clear.setFill()
        bounds.fill()

        let accent = active ? NSColor(calibratedRed: 0.28, green: 0.68, blue: 1.0, alpha: 1.0) : NSColor.systemRed
        let foreground = NSColor.labelColor
        let muted = NSColor.labelColor.withAlphaComponent(0.42)

        drawWindow(in: NSRect(x: 5.0, y: 7.0, width: 12.0, height: 9.0), stroke: muted, fillAlpha: 0.10)
        drawWindow(in: NSRect(x: 3.6, y: 5.0, width: 12.8, height: 9.4), stroke: foreground.withAlphaComponent(0.62), fillAlpha: 0.16)
        drawWindow(in: NSRect(x: 6.2, y: 3.1, width: 12.8, height: 9.4), stroke: accent, fillAlpha: active ? 0.24 : 0.12)

        let command = "⌘" as NSString
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        command.draw(
            in: NSRect(x: 6.3, y: 2.7, width: 12.6, height: 11.2),
            withAttributes: [
                .font: NSFont.systemFont(ofSize: 9.5, weight: .bold),
                .foregroundColor: foreground,
                .paragraphStyle: paragraph
            ]
        )

        drawChevron(points: [
            NSPoint(x: 3.0, y: 11.0),
            NSPoint(x: 1.2, y: 9.0),
            NSPoint(x: 3.0, y: 7.0)
        ], color: accent.withAlphaComponent(active ? 0.95 : 0.55))

        drawChevron(points: [
            NSPoint(x: 19.0, y: 11.0),
            NSPoint(x: 20.8, y: 9.0),
            NSPoint(x: 19.0, y: 7.0)
        ], color: accent.withAlphaComponent(active ? 0.95 : 0.55))

        image.unlockFocus()
        image.isTemplate = false
        image.size = size
        return image
    }

    private static func drawWindow(in rect: NSRect, stroke: NSColor, fillAlpha: CGFloat) {
        let path = NSBezierPath(roundedRect: rect, xRadius: 2.2, yRadius: 2.2)
        NSColor.labelColor.withAlphaComponent(fillAlpha).setFill()
        path.fill()
        stroke.setStroke()
        path.lineWidth = 1.35
        path.stroke()
    }

    private static func drawChevron(points: [NSPoint], color: NSColor) {
        let path = NSBezierPath()
        path.move(to: points[0])
        path.line(to: points[1])
        path.line(to: points[2])
        color.setStroke()
        path.lineWidth = 1.8
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
    }
}
