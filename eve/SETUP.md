# eve 호스트 초기 세팅 절차

## 1. Xcode Command Line Tools
```bash
xcode-select --install
```

## 2. Homebrew 설치
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## 3. dotfiles clone
```bash
git clone git@github.com:deuxksy/dotfiles.git ~/git/dotfiles
```

## 4. Brewfile 패키지 설치
```bash
cd ~/git/dotfiles && brew bundle
```

## 5. Oh My Zsh
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## 6. Powerlevel10k
```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

## 7. stow 배포
```bash
cd ~/git/dotfiles && stow -t ~ base eve
```

## 8. mise로 런타임 설치
```bash
cd ~ && mise install
```

## 9. 셸 재시작
```bash
exec zsh
```

## 검증 항목
- [ ] `eza` → ls 대체 동작
- [ ] `nvim` → LazyVim 플러그인 로드
- [ ] `mise list` → go, node, python 등 설치 확인
- [ ] `p10k configure` → 프롬프트 커스터마이징
