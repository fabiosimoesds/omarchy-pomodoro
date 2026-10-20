# 🍅 Omarchy Pomodoro

Widget de pomodoro para a barra do [Omarchy](https://omarchy.org). Um tomatinho fica na barra e, durante uma sessão, mostra o tempo restante ao lado.

- Passe o mouse sobre o tomate para abrir o popup com atalhos de 15, 30 e 45 minutos, ou escolha um tempo personalizado (1 a 600 min).
- Quando o tempo acaba, toca um som suave e o tomate cresce e fica tremendo até você clicar nele.
- Clique com o botão direito durante uma sessão para parar o timer.

## Instalação

```bash
omarchy plugin add https://github.com/fabiosimoesds/omarchy-pomodoro.git --enable
```

O instalador pergunta em qual seção da barra colocar o widget. Para escolher uma posição exata:

```bash
omarchy plugin enable fabiosimoesds.pomodoro --section center --after omarchy.weather
```

## Atualizar e remover

```bash
omarchy plugin update fabiosimoesds.pomodoro
omarchy plugin remove fabiosimoesds.pomodoro
```

Se o widget continuar com a versão antiga depois de atualizar, reinicie o shell com `omarchy restart shell`.

## Requisitos

Nada além de uma instalação padrão do Omarchy: o som usa `pw-play` (ou `paplay`) com `/usr/share/sounds/freedesktop/stereo/complete.oga`, e o tomate usa a fonte Noto Color Emoji.

## Licença

[MIT](LICENSE)
