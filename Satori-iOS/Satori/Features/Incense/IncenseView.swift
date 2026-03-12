import SwiftUI

// MARK: - 焚香主页面

struct IncenseView: View {
    @StateObject private var viewModel = IncenseViewModel()
    @EnvironmentObject private var hapticService: HapticService
    @Namespace private var modeAnimation

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 背景
                backgroundLayer

                VStack(spacing: 0) {
                    // 顶部标题 + 模式选项卡
                    headerSection

                    Spacer()

                    // 中心场景（倒计时 = 焚香 / 正计时 = 烟雾太极）
                    if viewModel.timerMode == .countdown {
                        countdownScene(in: geo)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                    } else {
                        countUpScene(in: geo)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                    }

                    Spacer()

                    // 计时器
                    timerDisplay

                    // 控制区
                    controlSection

                    Spacer().frame(height: 100)
                }
            }
            .simultaneousGesture(
                viewModel.state == .idle || viewModel.state == .paused || viewModel.state == .completed
                    ? modeSwitchGesture
                    : nil
            )
        }
        .sheet(isPresented: $viewModel.showCustomDuration) {
            CustomDurationSheet(viewModel: viewModel)
                .presentationDetents([.height(420)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        Color(.systemBackground)
            .overlay(
                SatoriColors.ricePaper
                    .opacity(0.3)
                    .blendMode(.multiply)
            )
            .ignoresSafeArea()
    }

    // MARK: - Header（标题 + 条状模式选项卡）

    private var headerSection: some View {
        HStack {
            Text("焚香")
                .font(SatoriTypography.largeTitle)
                .foregroundStyle(.primary)

            Spacer()

            // 条状圆角模式选项卡（倒 / 正）
            modeTabBar
        }
        .padding(.horizontal, SatoriTheme.spacingL)
        .padding(.top, SatoriTheme.spacingM)
    }

    // MARK: - 条状模式选项卡

    private var modeTabBar: some View {
        HStack(spacing: 0) {
            ForEach(IncenseViewModel.TimerMode.allCases, id: \.self) { mode in
                let isSelected = viewModel.timerMode == mode
                Button {
                    guard !isSelected else { return }
                    guard viewModel.state == .idle || viewModel.state == .paused || viewModel.state == .completed else { return }
                    hapticService.lightTap()
                    withAnimation(.easeInOut(duration: SatoriTheme.animNormal)) {
                        if viewModel.state != .idle { viewModel.reset() }
                        viewModel.timerMode = mode
                    }
                } label: {
                    Text(mode == .countdown ? "倒计时" : "正计时")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(isSelected ? .white : .secondary)
                        .frame(width: 56, height: 28)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(SatoriColors.incenseEmber.opacity(0.85))
                                    .matchedGeometryEffect(id: "modeTab", in: modeAnimation)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    // MARK: - 手势：上下滑动切换模式
    // 倒计时界面向下滑 → 正计时；正计时界面向上滑 → 倒计时

    private var modeSwitchGesture: some Gesture {
        DragGesture(minimumDistance: 40)
            .onEnded { value in
                let vertical = value.translation.height
                guard abs(vertical) > abs(value.translation.width) else { return }
                guard abs(vertical) > 50 else { return }

                // 向下滑（正值）→ 正计时；向上滑（负值）→ 倒计时
                let targetMode: IncenseViewModel.TimerMode = vertical > 0 ? .countUp : .countdown
                guard targetMode != viewModel.timerMode else { return }

                hapticService.lightTap()
                withAnimation(.easeInOut(duration: SatoriTheme.animNormal)) {
                    if viewModel.state != .idle { viewModel.reset() }
                    viewModel.timerMode = targetMode
                }
            }
    }

    // MARK: - 倒计时场景（焚香）

    @ViewBuilder
    private func countdownScene(in geo: GeometryProxy) -> some View {
        let sceneHeight = geo.size.height * 0.4
        let stickBaseHeight = sceneHeight * 0.5
        let burnerCenterY = sceneHeight * 0.28
        let visibleStickHeight = stickBaseHeight * (1 - viewModel.burnProgress)
        let stickBottomY = burnerCenterY - 18
        let stickTopY = stickBottomY - visibleStickHeight
        let stickCenterY = (stickBottomY + stickTopY) / 2

        ZStack {
            // 烟雾粒子（持续显示）
            SmokeParticleView(burnProgress: viewModel.burnProgress)
                .frame(width: 200, height: sceneHeight * 0.5)
                .offset(y: stickTopY - sceneHeight * 0.15)
                .opacity(viewModel.state == .running ? 1 : 0.3)

            // 香身
            if visibleStickHeight > 1 {
                IncenseStickView(burnProgress: viewModel.burnProgress)
                    .frame(width: 6, height: visibleStickHeight)
                    .offset(y: stickCenterY)
            }

            // 余烬灼热点
            if viewModel.state == .running && visibleStickHeight > 1 {
                IncenseEmberView()
                    .frame(width: 14, height: 10)
                    .offset(y: stickTopY)
            }

            // 香灰微粒
            if viewModel.state == .running {
                AshParticleView()
                    .frame(width: 30, height: max(10, stickBottomY - stickTopY + 30))
                    .offset(y: stickTopY + 5)
            }

            // 香炉
            IncenseBurnerView()
                .frame(width: 80, height: 50)
                .offset(y: burnerCenterY)
        }
        .frame(height: sceneHeight)
    }

    // MARK: - 正计时场景（烟雾太极）

    @ViewBuilder
    private func countUpScene(in geo: GeometryProxy) -> some View {
        let sceneHeight = geo.size.height * 0.4

        ZStack {
            // 烟雾粒子（持续上升）
            SmokeParticleView(burnProgress: 0)
                .frame(width: 200, height: sceneHeight * 0.6)
                .offset(y: sceneHeight * 0.1)
                .opacity(viewModel.state == .running ? 1 : 0.3)

            // 太极 Liquid Glass 容器
            TaiChiGlassView(fillProgress: viewModel.state == .running ? viewModel.burnProgress : 0)
                .frame(width: 100, height: 100)
                .offset(y: -sceneHeight * 0.12)
        }
        .frame(height: sceneHeight)
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        Text(viewModel.formattedTime)
            .font(SatoriTypography.timer)
            .foregroundStyle(.primary.opacity(0.8))
            .padding(.bottom, SatoriTheme.spacingM)
            .contentTransition(.numericText())
            .animation(.linear(duration: 0.05), value: viewModel.timerMode == .countdown ? viewModel.remainingTime : viewModel.elapsedTime)
    }

    // MARK: - Controls

    private var controlSection: some View {
        VStack(spacing: SatoriTheme.spacingM) {
            // 预设时长选择（仅倒计时 + 空闲时显示）
            if viewModel.state == .idle && viewModel.timerMode == .countdown {
                presetPicker
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // 控制按钮
            HStack(spacing: SatoriTheme.spacingL) {
                switch viewModel.state {
                case .idle:
                    if viewModel.timerMode == .countdown {
                        primaryButton("点燃", icon: "flame") {
                            hapticService.mediumTap()
                            viewModel.start()
                        }
                    } else {
                        primaryButton("开始", icon: "play.fill") {
                            hapticService.mediumTap()
                            viewModel.start()
                        }
                    }
                case .running:
                    secondaryButton("暂停", icon: "pause") {
                        hapticService.lightTap()
                        viewModel.pause()
                    }
                case .paused:
                    primaryButton("继续", icon: "play.fill") {
                        hapticService.lightTap()
                        viewModel.start()
                    }
                    secondaryButton("结束", icon: "xmark") {
                        hapticService.lightTap()
                        viewModel.reset()
                    }
                case .completed:
                    primaryButton("再燃一炷", icon: "flame") {
                        hapticService.mediumTap()
                        viewModel.reset()
                    }
                }
            }
            .animation(.easeInOut(duration: SatoriTheme.animNormal), value: viewModel.state)
        }
        .padding(.horizontal, SatoriTheme.spacingL)
    }

    // MARK: - Preset Picker（含自定义入口）

    private var presetPicker: some View {
        HStack(spacing: SatoriTheme.spacingS) {
            ForEach(viewModel.presets, id: \.minutes) { preset in
                let isSelected = viewModel.totalDuration == TimeInterval(preset.minutes * 60)
                Button {
                    hapticService.lightTap()
                    viewModel.selectPreset(minutes: preset.minutes)
                } label: {
                    Text(preset.label)
                        .font(SatoriTypography.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isSelected
                                      ? SatoriColors.incenseEmber.opacity(0.15)
                                      : Color.secondary.opacity(0.08))
                        )
                        .foregroundStyle(isSelected ? SatoriColors.incenseEmber : .secondary)
                }
            }

            // 自定义时长入口
            Button {
                hapticService.lightTap()
                viewModel.customMinutes = Int(viewModel.totalDuration / 60)
                viewModel.showCustomDuration = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 12))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.08))
                    )
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Button Builders

    private func primaryButton(_ text: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(text, systemImage: icon)
                .font(SatoriTypography.subtitle)
                .foregroundStyle(.white)
                .padding(.horizontal, SatoriTheme.spacingL)
                .padding(.vertical, SatoriTheme.spacingM)
                .background(
                    Capsule().fill(SatoriColors.incenseEmber)
                )
                .satoriShadow(SatoriTheme.shadowSubtle)
        }
    }

    private func secondaryButton(_ text: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(text, systemImage: icon)
                .font(SatoriTypography.subtitle)
                .foregroundStyle(.primary)
                .padding(.horizontal, SatoriTheme.spacingL)
                .padding(.vertical, SatoriTheme.spacingM)
                .background(
                    Capsule()
                        .fill(Color.secondary.opacity(0.1))
                )
        }
    }
}

// MARK: - 自定义时长弹窗（含香的实时预览）

struct CustomDurationSheet: View {
    @ObservedObject var viewModel: IncenseViewModel
    @Environment(\.dismiss) private var dismiss

    /// 根据时长映射香的高度（40 ~ 160 pt）
    private var previewStickHeight: CGFloat {
        let ratio = CGFloat(viewModel.customMinutes - IncenseViewModel.minMinutes)
            / CGFloat(IncenseViewModel.maxMinutes - IncenseViewModel.minMinutes)
        return 40 + ratio * 120
    }

    /// 根据时长映射香的粗细（3 ~ 8 pt）
    private var previewStickWidth: CGFloat {
        let ratio = CGFloat(viewModel.customMinutes - IncenseViewModel.minMinutes)
            / CGFloat(IncenseViewModel.maxMinutes - IncenseViewModel.minMinutes)
        return 3 + ratio * 5
    }

    var body: some View {
        VStack(spacing: SatoriTheme.spacingL) {
            // 标题
            Text("自定义专注时长")
                .font(SatoriTypography.title)
                .padding(.top, SatoriTheme.spacingM)

            // 时长数字
            Text("\(viewModel.customMinutes) 分钟")
                .font(SatoriTypography.timer)
                .foregroundStyle(SatoriColors.incenseEmber)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.15), value: viewModel.customMinutes)

            // 香的实时预览
            ZStack(alignment: .bottom) {
                // 香身
                RoundedRectangle(cornerRadius: previewStickWidth / 3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [SatoriColors.sandalwood, SatoriColors.sandalwood.opacity(0.85)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: previewStickWidth, height: previewStickHeight)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.customMinutes)

                // 香炉
                IncenseBurnerView()
                    .frame(width: 50, height: 30)
                    .offset(y: 14)
            }
            .frame(height: 180)

            // 滑块
            VStack(spacing: SatoriTheme.spacingS) {
                Slider(
                    value: Binding(
                        get: { Double(viewModel.customMinutes) },
                        set: { viewModel.customMinutes = Int($0) }
                    ),
                    in: Double(IncenseViewModel.minMinutes)...Double(IncenseViewModel.maxMinutes),
                    step: 1
                )
                .tint(SatoriColors.incenseEmber)

                HStack {
                    Text("\(IncenseViewModel.minMinutes) 分钟")
                        .font(SatoriTypography.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(IncenseViewModel.maxMinutes) 分钟")
                        .font(SatoriTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, SatoriTheme.spacingL)

            // 确认按钮
            Button {
                viewModel.applyCustomDuration()
                dismiss()
            } label: {
                Text("确定")
                    .font(SatoriTypography.subtitle)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: SatoriTheme.cornerMedium, style: .continuous)
                            .fill(SatoriColors.incenseEmber)
                    )
            }
            .padding(.horizontal, SatoriTheme.spacingL)

            Spacer()
        }
    }
}

// MARK: - 香身（竖直渐变线条 —— 仅渲染未燃段 + 顶部薄灰 + 发光线）

struct IncenseStickView: View {
    var burnProgress: CGFloat

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            // 顶端微薄灰段（已燃灰色，约 4-6pt）
            let ashHeight: CGFloat = burnProgress > 0.01 ? min(6, h * 0.08) : 0

            ZStack(alignment: .top) {
                // 未燃部分 —— 檀木色
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [SatoriColors.sandalwood, SatoriColors.sandalwood.opacity(0.85)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                // 顶端薄灰层 —— 覆盖在未燃段顶部
                if ashHeight > 0 {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.gray.opacity(0.35), .gray.opacity(0.5)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(height: ashHeight)

                        // 1px 橘红发光线 —— 灰与木的交界
                        Rectangle()
                            .fill(SatoriColors.incenseEmber.opacity(0.5))
                            .frame(height: 1.5)
                            .blur(radius: 1.5)

                        Spacer(minLength: 0)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
        }
    }
}

// MARK: - 香炉

struct IncenseBurnerView: View {
    var body: some View {
        ZStack {
            // 炉身
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [SatoriColors.sandalwood, SatoriColors.sandalwood.opacity(0.7)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            // 炉口
            Ellipse()
                .fill(SatoriColors.inkSmoke.opacity(0.3))
                .scaleEffect(x: 0.85, y: 0.3)
                .offset(y: -15)
            // 铜绿点缀边
            Ellipse()
                .strokeBorder(
                    SatoriColors.verdigris.opacity(0.4),
                    lineWidth: 1.5
                )
        }
    }
}

// MARK: - 香灰掉落粒子

struct AshParticleView: View {
    @StateObject private var engine = AshParticleEngine()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { _ in
            Canvas { context, size in
                engine.update(canvasSize: size)
                for p in engine.particles {
                    let alpha = p.opacity * p.life
                    guard alpha > 0.01 else { continue }
                    let rect = CGRect(
                        x: p.x - p.radius, y: p.y - p.radius,
                        width: p.radius * 2, height: p.radius * 2
                    )
                    var ctx = context
                    ctx.opacity = alpha
                    ctx.fill(Path(ellipseIn: rect), with: .color(.gray.opacity(0.5)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

final class AshParticleEngine: ObservableObject {
    struct Particle {
        var x, y, vx, vy, radius: CGFloat
        var opacity: Double
        var life, decay: Double
    }

    var particles: [Particle] = []
    private let maxParticles = 15

    func update(canvasSize: CGSize) {
        if particles.count < maxParticles && Double.random(in: 0...1) < 0.015 {
            let p = Particle(
                x: canvasSize.width / 2 + CGFloat.random(in: -2...2),
                y: 0,
                vx: CGFloat.random(in: -0.15...0.15),
                vy: CGFloat.random(in: 0.3...0.8),
                radius: CGFloat.random(in: 0.5...1.5),
                opacity: Double.random(in: 0.3...0.6),
                life: 1.0,
                decay: Double.random(in: 0.008...0.02)
            )
            particles.append(p)
        }

        for i in particles.indices.reversed() {
            particles[i].x += particles[i].vx + sin(particles[i].y * 0.05) * 0.08
            particles[i].y += particles[i].vy
            particles[i].life -= particles[i].decay
            if particles[i].life <= 0 || particles[i].y > canvasSize.height {
                particles.remove(at: i)
            }
        }
    }
}

#Preview("Incense") {
    IncenseView()
        .environmentObject(HapticService())
}
