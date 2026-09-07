# fcitx5 Wayland 프론트엔드 전환 가이드 (mo)

## 현재 상태

- `waylandFrontend = false` (XIM 모드)
- 한영 전환: `Shift+Space`
- 동작하지만 후보창 깜빡임 등 Wayland 이슈 있을 수 있음

## Wayland 프론트엔드로 전환 (권장)

### 1. 설정 변경

`nix/nixos/modules/desktop/kde.nix`에서:

```nix
waylandFrontend = false;  # → true로 변경
```

### 2. KDE 시스템 설정 (수동, 1회)

1. mo에 로그인 (물리적 콘솔)
2. **시스템 설정 → 가상 키보드 → Fcitx 5** 선택
3. 로그아웃 후 다시 로그인

### 3. 확인

```bash
fcitx5-diagnose 2>/dev/null | grep -A5 "Wayland"
```

"Wayland input method frontend"가 활성화되어 있으면 OK.

### 4. 오른쪽 Alt를 한영키로 변경 (선택)

`nix/nixos/modules/desktop/kde.nix`에서 트리거 키 변경:

```nix
# Shift+Space 대신 Hangul 키 사용
Hotkey.TriggerKeys = "Hangul";
Hotkey.Trigger = "Hangul";
```

`nix/nixos/hosts/mo/default.nix`에 이미 설정됨:

```nix
XKB_DEFAULT_OPTIONS = "korean:ralt_hangul";
```

## 참고

- https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland#KDE_Plasma
- KDE Virtual Keyboard 설정이 필수 (NixOS로 선언적 설정 불가)
- Wayland 프론트엔드 사용 시 GTK_IM_MODULE, QT_IM_MODULE 설정하면 안 됨
