//
//  TransferProgressButton.swift
//  potato card
//
//  iOS 风格的“传输到设备”主操作按钮：
//  - 空闲态显示纯色填充胶囊按钮（保持苹果系强调色背景）；
//  - 传输/等待态时按钮自身变成进度条，左侧到右侧线性填充进度，
//    并把文字替换为“准备中…/传输中 xx%”，避免使用系统
//    `.borderedProminent` 在 disabled 时丢失背景色的问题。
//

import SwiftUI

/// 传输到设备主按钮：空闲时为强调色胶囊按钮；传输/等待时变成苹果风格的进度条按钮。
struct TransferProgressButton: View {
    /// 空闲时按钮上显示的文案。
    let idleTitle: String
    /// 传输中按钮上显示的前缀文案，最终会拼接 “xx%”。
    let inProgressTitle: String
    /// 当前传输进度，范围 [0, 1]。
    let progress: Double
    /// 是否处于传输/等待状态（决定是否显示进度条）。
    let isInProgress: Bool
    /// 是否允许点击（一般传 `activeDevice != nil`）。
    let isEnabled: Bool
    /// 点击空闲按钮时的回调。
    let action: () -> Void

    /// 整体高度。默认 50，与 `controlSize(.large)` 视觉一致。
    var height: CGFloat = 50
    /// 字号。
    var fontSize: CGFloat = 16
    /// 主色，默认跟随系统强调色，保证暗色模式自动适配。
    var tint: Color = .accentColor

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(.plain)
        // 没设备时使用真正的 .disabled（系统会自动降透明 + 屏蔽 VoiceOver 操作）；
        // 传输中只是临时不接受点击，但要保留按钮的强调色显示进度条，
        // 因此用 .allowsHitTesting(false) 而不是 .disabled，避免按钮整体被系统压暗。
        .disabled(!isEnabled)
        .allowsHitTesting(isEnabled && !isInProgress)
        .animation(.easeInOut(duration: 0.18), value: isInProgress)
        .animation(.linear(duration: 0.15), value: clampedProgress)
    }

    private var label: some View {
        let showsFill = isInProgress

        return ZStack(alignment: .leading) {
            // 底部胶囊：传输中调暗，作为进度条的“轨道”，避免点击区视觉消失。
            Capsule(style: .continuous)
                .fill(showsFill ? tint.opacity(0.28) : tint)

            if showsFill {
                GeometryReader { proxy in
                    // 复用按钮自身空间作为进度条，最小宽度等于胶囊高度，避免初始 0% 出现一个三角形。
                    Capsule(style: .continuous)
                        .fill(tint)
                        .frame(
                            width: min(
                                proxy.size.width,
                                max(height, proxy.size.width * clampedProgress)
                            )
                        )
                }
                .allowsHitTesting(false)
            }

            Text(currentTitle)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(.white)
                .monospacedDigit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: height)
        .clipShape(Capsule(style: .continuous))
        .contentShape(Capsule(style: .continuous))
    }

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var currentTitle: String {
        guard isInProgress else { return idleTitle }
        return "\(inProgressTitle) \(Int(clampedProgress * 100))%"
    }
}

/// 与 `TransferProgressButton` 配对的次操作按钮：使用相同的胶囊形状、字号与高度，
/// 视觉上模仿 iOS 26 “tinted capsule” —— 半透明 tint 填充 + 同色文字 + 同色描边，
/// 这样和主按钮放在一起时尺寸/形状/节奏完全统一，不会出现一大一小、深浅不一的割裂感。
struct TransferSecondaryButton: View {
    /// 按钮文案。
    let title: String
    /// 可选的 SF Symbol 图标名。
    var systemImage: String? = nil
    /// 是否允许点击。
    let isEnabled: Bool
    /// 点击回调。
    let action: () -> Void

    /// 整体高度。默认与主按钮 `TransferProgressButton.height` 对齐。
    var height: CGFloat = 50
    /// 字号。
    var fontSize: CGFloat = 16
    /// 文案 / 描边 / 填充共用的强调色。
    var tint: Color = .secondary
    /// 高亮态：背景填充更深，类似 iOS 系统“tinted button”的强调态。
    /// 在“已保存手动调整”这类需要提示的场景下打开，配合 `tint = .yellow`。
    var highlighted: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: fontSize, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: fontSize, weight: .semibold))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: height)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(highlighted ? 0.28 : 0.14))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(tint.opacity(highlighted ? 0.55 : 0.0), lineWidth: 1)
            )
            .clipShape(Capsule(style: .continuous))
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#if DEBUG
#Preview("Idle") {
    TransferProgressButton(
        idleTitle: "传输到设备",
        inProgressTitle: "传输中",
        progress: 0,
        isInProgress: false,
        isEnabled: true,
        action: {}
    )
    .padding()
}

#Preview("In progress 42%") {
    TransferProgressButton(
        idleTitle: "传输到设备",
        inProgressTitle: "传输中",
        progress: 0.42,
        isInProgress: true,
        isEnabled: true,
        action: {}
    )
    .padding()
}

#Preview("Disabled (no device)") {
    TransferProgressButton(
        idleTitle: "传输到设备",
        inProgressTitle: "传输中",
        progress: 0,
        isInProgress: false,
        isEnabled: false,
        action: {}
    )
    .padding()
}

#Preview("Pair: primary + secondary") {
    VStack(spacing: 12) {
        TransferProgressButton(
            idleTitle: "传输到设备",
            inProgressTitle: "传输中",
            progress: 0,
            isInProgress: false,
            isEnabled: true,
            action: {}
        )
        TransferSecondaryButton(
            title: "手动调整",
            systemImage: "slider.horizontal.3",
            isEnabled: true,
            action: {}
        )
    }
    .padding()
}

#Preview("Pair: in-progress + customized") {
    VStack(spacing: 12) {
        TransferProgressButton(
            idleTitle: "传输到设备",
            inProgressTitle: "传输中",
            progress: 0.6,
            isInProgress: true,
            isEnabled: true,
            action: {}
        )
        TransferSecondaryButton(
            title: "手动调整",
            systemImage: "slider.horizontal.3",
            isEnabled: false,
            action: {},
            tint: .yellow,
            highlighted: true
        )
    }
    .padding()
}
#endif
