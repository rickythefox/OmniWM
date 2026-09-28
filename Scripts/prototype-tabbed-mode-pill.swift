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

// A: compact capsule with icon + text near the column top
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

// B: macOS volume-style HUD square in the column center
struct CenterHUD: View {
    let on: Bool
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol(on: on))
                .font(.system(size: 50))
                .foregroundStyle(on ? accent : .white.opacity(0.7))
            Text(label(on: on)).font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(.white)
        .frame(width: 170, height: 140)
        .background(fill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(stroke))
    }
}

// C: full-width strip at the column top with an ON/OFF chip
struct TopBanner: View {
    let on: Bool
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: symbol(on: on))
            Text("Tabbed mode")
            Spacer()
            Text(on ? "ON" : "OFF")
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(on ? accent : Color.gray.opacity(0.6), in: Capsule())
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(fill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(stroke))
    }
}

// D: icon-only circle; off state is struck through
struct IconOnly: View {
    let on: Bool
    var body: some View {
        ZStack {
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 20))
                .foregroundStyle(on ? accent : .white.opacity(0.7))
            if !on {
                Capsule().frame(width: 30, height: 3).rotationEffect(.degrees(-45)).foregroundStyle(.white)
            }
        }
        .frame(width: 46, height: 46)
        .background(fill, in: Circle())
        .overlay(Circle().strokeBorder(stroke))
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
    Variant(key: "A", name: "Top pill", note: "Icon + text capsule, top center", alignment: .top, inset: 40) { AnyView(TopPill(on: $0)) },
    Variant(key: "B", name: "Center HUD", note: "System HUD style, column center", alignment: .center, inset: 0) { AnyView(CenterHUD(on: $0)) },
    Variant(key: "C", name: "Top banner", note: "Column-wide strip with ON/OFF chip", alignment: .top, inset: 36) { AnyView(TopBanner(on: $0).padding(.horizontal, 12)) },
    Variant(key: "D", name: "Icon only", note: "Compact, no text; off is struck through", alignment: .top, inset: 40) { AnyView(IconOnly(on: $0)) },
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
            Text("Toggle Column Tabbed indicator - options (#759)")
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
