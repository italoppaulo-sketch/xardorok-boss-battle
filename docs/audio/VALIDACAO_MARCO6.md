# Validação executada — Marco 6

## Ambiente

Godot **4.7.2.stable.official.ed1daf0bf**, Linux; executável e Xvfb reutilizados do cache, sem novo download. Renderização gráfica Compatibility/OpenGL com Mesa llvmpipe, viewport 1200 × 700. FFmpeg/ffprobe mediram e converteram a captura nativa. Não foi executada validação em Windows ou GPU/dispositivo de áudio físico.

## Resultados

- **1.696 verificações funcionais, zero falhas:** as 1.464 verificações do projeto 5.2, 211 novas de catálogo/eventos/sincronização e 21 novas de controles de áudio. Inclui importação, início da cena e encerramento apropriado dos streams.
- **36 novas partidas de regressão:** 18 vitórias e 18 derrotas, nenhuma falha de integridade. Todas as métricas por partida coincidem com as da base 5.2, excluindo somente o tempo de processamento. Dados desta execução preservados em `balance_regression.json`; o relatório original do Marco 5.2 não foi sobrescrito.
- **77 verificações gráficas:** 21 do painel/teclas de áudio e 56 da entrada/câmera/seleção do 5.2, zero falhas.
- **Uma partida completa com gravação nativa de imagem e som:** estratégia agressiva, semente 42, vitória na rodada 6, zero falhas, 355 cues registrados. Sem alteração de HP, dano, mana, recursos, estado de iniciativa ou RNG depois da semente inicial. Fonte: `tests/capture_audio_marco6.gd`.
- 63 arquivos do catálogo foram decodificados e medidos, nenhum silencioso ou com pico próximo de escala cheia. Hashes e medidas estão em `audio_metrics.json`.
- Gdlint de scripts e testes e `git diff --check`: sem problemas.

As 211 verificações novas percorrem as 30 combinações reais de personagem/habilidade (incluindo os sete ataques básicos e o laser). Para cada uma, verificam execução e áudio emitido pela apresentação, preservando unidades e rodada. Também cobrem gelo no martelo, dois impactos separados, sacrifício de 24 HP, carga única com três saltos elétricos, eventos de estado/expiração, reação defensiva, contato amortecido, morte/retirada de lacaio, fase 2, buses, limite de vozes, prioridade, reinício, coroa, título, fanfarra, pular e derrota.

O teste de controles usa entradas de teclado F10/M e os sinais reais de sliders/botões, verifica música muda com SFX ativos e mantém os volumes ao reiniciar. Os testes históricos que criam a cena receberam somente a limpeza de áudio ao encerrar; suas condições de aprovação não foram enfraquecidas. O teste de inicialização mantém 120 frames e encerra os streams antes de fechar, dando tempo à fila do servidor de áudio para liberar seus recursos.

## Mixagem realmente capturada

O Movie Maker gravou **3.807 frames a 30 FPS**, totalizando **126,9 s**, com áudio PCM estéreo a 48 kHz do próprio AudioServer. Não houve montagem de efeitos por fora da gameplay. A versão final MP4 contém H.264 1200 × 700 e AAC estéreo.

| Medida | Gravação nativa | MP4 entregue |
| --- | ---: | ---: |
| Loudness integrado | −19,0 LUFS | −19,1 LUFS |
| Faixa de loudness | 5,5 LU | 5,5 LU |
| Pico verdadeiro | −3,1 dBFS | −3,2 dBFS |

Nenhum pico de clipping foi detectado nessa partida. Isso não prova que qualquer combinação possível de volumes escolhidos pelo usuário terá a mesma dinâmica; o limiter do Master e o limite de vozes permanecem como proteção em execução.

O trace inclui 8 impactos de martelo, Fushigiri com custo e ruptura, flechas de gelo/energia, cura e magia violeta, 5 saltos elétricos, 4 surgimentos de acólitos, 9 emissões/impactos de laser, 11 quedas/impactos de meteoros, morte e dissipação de lacaio, fase 2, contato da coroa e fanfarra. A conjuração de Chuva de Meteoros ocorreu uma vez; as demais quedas incluem as reações do chefe. A gravação não depende de causar artificialmente uma vitória.

Na captura, a Fushigiri ocorre por volta de **00:22**, a fase 2 por volta de **00:49**, o golpe final por volta de **01:58**, e coroa/título por volta de **02:00**. O trace completo está em `capture_executed.json`.

## Preservação

Comparação com `2db39f1…`: nenhum arquivo de `scripts/data/`, `scripts/combat/`, `scripts/abilities/`, `scripts/ai/`, sprites, texturas, câmera ou `project.godot` foi modificado. As mudanças existentes são em apresentação (`arena.gd`, `main.gd`, `victory_sequence.gd`), módulos novos de áudio, arquivos sonoros, testes e documentação.

A duração visual da vitória é agora 7,2 s para comportar a frase musical, mantendo o contato da coroa e a revelação do título nos tempos originais. Não altera o relógio de combate. Os dois loops musicais têm a mesma duração (aproximadamente 87,2 s), tocados alinhados e combinados por crossfade de 1,5 s na fase 2. As emendas foram medidas, sem inserir frames de silêncio entre o fim e o começo.

## Limites da evidência

Houve validação técnica e inspeção visual das capturas. Não se declara escuta humana, teste em fones/caixas físicos ou busca exaustiva de similaridade musical. Naturalidade, timbre e satisfação artística devem ser avaliados pelo usuário no jogo ou no vídeo. Fontes generativas em MP3, ausência de MIDI/stems completos e condições de uso estão documentadas em `FONTES_E_LICENCAS.md`. A reprodução no Windows e a exportação executável permanecem pendentes de teste no computador do usuário.

## Reprodução

```sh
python tests/run_tests.py --godot CAMINHO_DO_GODOT
godot --path . --script tests/test_audio_marco6.gd
godot --path . --script tests/test_audio_ui_marco6.gd
godot --path . --rendering-method gl_compatibility --write-movie gameplay.avi --fixed-fps 30 --script tests/capture_audio_marco6.gd
```

`--skip-encounters` no runner reutiliza o lote já concluído, útil para correções exclusivas de apresentação. Não é usado para alegar uma execução de partidas que não ocorreu.
