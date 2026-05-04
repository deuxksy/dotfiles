# 운영 및 안전

- 파괴적 명령어: 파일 삭제(`rm`) 사용시 사용자에게 확인 받는다
- 파일 경로: 절대 경로보다는 프로젝트 루트 기준의 상대 경로를 사용한다
- Proxmox API: Read(GET)은 자유롭게 실행. Create(POST), Update(PUT), Delete(DELETE)는 사용자 승인 후 실행
- K8S(kubectl): get, describe, logs 등 읽기 전용은 자유롭게 실행. create, delete, edit, patch, apply, drain, cordon, uncordon 등 변경 작업은 사용자 승인 후 실행
