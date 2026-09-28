// PROTOTYPE - throwaway, do not merge. Issue #759: "Toggle Column Tabbed" indicator.
// Question: what should the transient, click-through "Tabbed mode on/off" pill look like?
// Renders a comparison sheet (variants x on/off) over a mock focused column to a PNG for the issue discussion.
// Run: swift Scripts/prototype-tabbed-mode-pill.swift [output.png] [light|dark]

import AppKit
import SwiftUI

// MARK: - Shared copy and style

func symbol(on: Bool) -> String { on ? "rectangle.stack.fill" : "rectangle" }
func label(on: Bool) -> String { on ? "Tabbed mode on" : "Tabbed mode off" }

// Translucent dark fill + hairline stroke, same recipe as MonitorIdentificationBadge
let fill = Color.black.opacity(0.72)
let stroke = Color.white.opacity(0.22)
let accent = Color(red: 0.25, green: 0.6, blue: 1.0)

// MARK: - Variants

// A1: compact capsule with icon + text, dark translucent fill
struct TopPill: View {
    let on: Bool
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: symbol(on: on)).foregroundStyle(on ? accent : .white.opacity(0.7))
            Text(label(on: on))
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .frame(height: 32)
        .background(fill, in: Capsule())
        .overlay(Capsule().strokeBorder(stroke))
    }
}

// A2: lighter, more see-through pill, text only
struct GlassPill: View {
    let on: Bool
    var body: some View {
        Text(label(on: on))
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 1.5)
            .padding(.horizontal, 14)
            .frame(height: 30)
            .background(Color.black.opacity(0.4), in: Capsule())
            .overlay(Capsule().strokeBorder(stroke))
    }
}

// A3: color carries the state - accent fill when on, neutral grey when off
struct TintedPill: View {
    let on: Bool
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: symbol(on: on))
            Text(label(on: on))
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .frame(height: 32)
        .background(on ? accent.opacity(0.8) : Color(white: 0.35).opacity(0.75), in: Capsule())
        .overlay(Capsule().strokeBorder(stroke))
    }
}

// A4: fixed label with an ON/OFF chip inside the pill
struct ChipPill: View {
    let on: Bool
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "rectangle.stack")
            Text("Tabbed mode")
            Text(on ? "ON" : "OFF")
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(on ? accent : Color.gray.opacity(0.6), in: Capsule())
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.leading, 13)
        .padding(.trailing, 5)
        .frame(height: 32)
        .background(fill, in: Capsule())
        .overlay(Capsule().strokeBorder(stroke))
    }
}

struct Variant {
    let key: String
    let name: String
    let note: String
    let alignment: Alignment
    let inset: CGFloat
    let view: (Bool) -> AnyView
}

let variants: [Variant] = [
    Variant(key: "A1", name: "Dark pill", note: "Icon + text, dark translucent fill", alignment: .top, inset: 40) { AnyView(TopPill(on: $0)) },
    Variant(key: "A2", name: "Glass pill", note: "Text only, very see-through", alignment: .top, inset: 40) { AnyView(GlassPill(on: $0)) },
    Variant(key: "A3", name: "Tinted pill", note: "Accent fill when on, grey when off", alignment: .top, inset: 40) { AnyView(TintedPill(on: $0)) },
    Variant(key: "A4", name: "Chip pill", note: "Fixed label + ON/OFF chip", alignment: .top, inset: 40) { AnyView(ChipPill(on: $0)) },
]

// MARK: - Mock focused column (fake window with busy content so transparency is judgeable)

struct MockColumn: View {
    let dark: Bool
    var body: some View {
        let bg = dark ? Color(white: 0.14) : Color(white: 0.97)
        let line = dark ? Color(white: 0.3) : Color(white: 0.82)
        VStack(alignment: .leading, spacing: 0) {
            // Title bar with traffic lights
            HStack(spacing: 7) {
                ForEach([Color.red, .yellow, .green], id: \.self) { Circle().fill($0.opacity(0.85)).frame(width: 11, height: 11) }
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(dark ? Color(white: 0.2) : Color(white: 0.91))
            // Content: heading, image block, text lines
            VStack(alignment: .leading, spacing: 9) {
                RoundedRectangle(cornerRadius: 3).fill(line).frame(width: 150, height: 14)
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: [.orange, .pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 90)
                ForEach(0..<9, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3).fill(line).frame(width: [250, 230, 260, 190, 245, 220, 255, 170, 235][i], height: 8)
                }
            }
            .padding(12)
            Spacer(minLength: 0)
        }
        .frame(width: 300, height: 340)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        // OmniWM-style focus border
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(accent, lineWidth: 3))
    }
}

// MARK: - Comparison sheet

struct Sheet: View {
    let dark: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Toggle Column Tabbed indicator - top pill variations (#759)")
                .font(.system(size: 20, weight: .bold))
            Text("Transient, click-through, fades after ~1s; a repeated toggle replaces it. Left: toggled on, right: toggled off.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            // 2x2 grid keeps the image readable when GitHub scales it to comment width
            Grid(alignment: .topLeading, horizontalSpacing: 36, verticalSpacing: 24) {
                ForEach([0, 2], id: \.self) { row in
                    GridRow {
                        ForEach(variants[row..<row + 2], id: \.key) { v in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(v.key)  \(v.name)").font(.system(size: 15, weight: .semibold))
                                Text(v.note).font(.system(size: 12)).foregroundStyle(.secondary)
                                HStack(spacing: 10) {
                                    ForEach([true, false], id: \.self) { on in
                                        MockColumn(dark: dark)
                                            .overlay(alignment: v.alignment) { v.view(on).padding(.top, v.inset) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(28)
        .foregroundStyle(dark ? .white : .black)
        .background(dark ? Color(white: 0.08) : Color(white: 0.86))
        .environment(\.colorScheme, dark ? .dark : .light)
    }
}

// MARK: - Render to PNG

let args = CommandLine.arguments.dropFirst()
let output = args.first ?? "dist/tabbed-mode-pill-options.png"
let dark = args.dropFirst().first == "dark"

MainActor.assumeIsolated {
    let renderer = ImageRenderer(content: Sheet(dark: dark))
    renderer.scale = 2
    guard let image = renderer.cgImage else { fatalError("render failed") }
    let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    let url = URL(fileURLWithPath: output)
    try! FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try! png.write(to: url)
    print("wrote \(output) (\(image.width)x\(image.height))")
}
