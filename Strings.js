.pragma library

// UI strings per language. "left" takes the remaining time as %1.
var table = {
  en: { left: "%1 left",       start: "Start",    stop: "Stop",      min: "min" },
  pt: { left: "%1 restantes",  start: "Iniciar",  stop: "Parar",     min: "min" },
  es: { left: "quedan %1",     start: "Iniciar",  stop: "Detener",   min: "min" },
  fr: { left: "%1 restantes",  start: "Démarrer", stop: "Arrêter",   min: "min" },
  de: { left: "noch %1",       start: "Start",    stop: "Stopp",     min: "Min." },
  it: { left: "%1 rimanenti",  start: "Avvia",    stop: "Ferma",     min: "min" },
  nl: { left: "nog %1",        start: "Start",    stop: "Stop",      min: "min" },
  pl: { left: "zostało %1",    start: "Start",    stop: "Zatrzymaj", min: "min" },
  ru: { left: "осталось %1",   start: "Старт",    stop: "Стоп",      min: "мин" },
  uk: { left: "залишилось %1", start: "Старт",    stop: "Стоп",      min: "хв" },
  tr: { left: "%1 kaldı",      start: "Başlat",   stop: "Durdur",    min: "dk" },
  ja: { left: "残り %1",       start: "開始",     stop: "停止",      min: "分" },
  zh: { left: "剩余 %1",       start: "开始",     stop: "停止",      min: "分钟" },
  ko: { left: "%1 남음",       start: "시작",     stop: "정지",      min: "분" }
}

// Accepts "pt", "pt_BR", "pt-BR" or "pt_BR.UTF-8"; anything unknown is English.
function forLanguage(code) {
  var lang = String(code || "").split(/[_.@-]/)[0].toLowerCase()
  return table[lang] || table.en
}
