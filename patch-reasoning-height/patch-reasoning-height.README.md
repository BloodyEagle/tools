# Patch: Высота блока Reasoning в Kilo Code (JetBrains IDE)

## Проблема
Развёрнутый блок Reasoning в нативном плагине `kilo.jetbrains` имеет высоту ~116px (5 строк + padding 16px) — недостаточно для чтения.

## Решение
Патч `ReasoningView.class` в `kilo.jetbrains.frontend.jar`:
- `bodyMaxRows`: 5 → 20 (строк)
- `bodyMaxHeight` padding: `JBUI.scale(16)` → `JBUI.scale(120)`
- Новая высота: ~520px

Работает для **любой JetBrains IDE**, в которую установлен плагин Kilo Code: WebStorm, IntelliJ IDEA, PyCharm, PhpStorm, RubyMine, CLion, GoLand, DataGrip, Rider, DataSpell, Aqua, RustRover, Fleet.

## Запуск (после обновления плагина Kilo Code)
1. **Закрыть все JetBrains IDE**
2. Открыть PowerShell **в любой папке** и выполнить:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "<путь>\patch-reasoning-height.ps1"
   ```
   Если автопоиск java.exe не сработает — укажите вручную (можно от любой IDE, лишь бы JBR был ≥ 11):
   ```powershell 
    powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.kilocode\tools\patch-reasoning-hight\patch-reasoning-height.ps1" `
    -JavaPath "<путь к JBR>\jbr\bin\java.exe"
    ```