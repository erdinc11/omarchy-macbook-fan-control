# Omarchy MacBook Fan Control

Omarchy üzerinde MacBook Air 11-inch (2013) için CPU sıcaklığını top bar'da gösteren ve fan kontrolü sağlayan özel Quickshell modülü.

Özellikler:

- CPU sıcaklığını tek top-bar ikonunda gösterir.
- Max Fan ile fanı maksimum hıza alır.
- 20–100% arasında sabit fan hızı slider'ı sunar.
- Min/Mid/Max fan curve sıcaklıklarını düzenler.
- Otomatik eğriye tek butonla geri döner.

## Kurulum

```bash
./install.sh
```

Kurulum root yardımcı komutlarını `/usr/local/bin` altına, Quickshell modülünü ise `~/.config/omarchy/bar/` altına kopyalar. `shell.json` içindeki sağ bar bölümünde şu kayıt bulunmalıdır:

```json
{
  "id": "local.fan-control",
  "type": "qml"
}
```

Kurulumdan sonra:

```bash
omarchy restart shell
```

Fan ayarlarının çalışması için `mbpfan` servisi ve Apple SMC fan sysfs arayüzü gerekir. Fan hızı işlemleri grafik polkit penceresi üzerinden yetkilendirilir.
