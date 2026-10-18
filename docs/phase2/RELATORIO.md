# Fase 2: transição musical e distribuição Windows

Data: 18/10/2026. Base: `feature/marco-6-1-audio-fix-windows-export`, commit `cf201e68fb5802db4198f607c2ceeb5d631a7c62`. Essa branch contém o Marco 6 completo (`1affb6e`) e a tentativa anterior. Trabalho em `fix/codex-phase2-audio-windows`, sem merge.

## Diagnóstico e limites da conclusão

O usuário descreveu um efeito sobreposto e trepidante, semelhante à interferência de um celular em uma caixa de som. Não há gravação desse defeito no computador do usuário. **A causa desse sintoma específico permanece não confirmada por audição. Esta entrega é candidata para validação, não uma declaração de resolução definitiva.**

Fluxo investigado: `Battle.deal_damage()` chama `_update_boss_phase()`; a condição é fase 1, chefe vivo e HP <= 50% do máximo (450 de 900). O evento `phase` entra na timeline da arena; `_apply_visual()` emite `audio_event`, ligado uma vez por `BattleAudio.bind()` a `on_visual()`. A fase é decidida no combate e a música acompanha o evento apresentado, não uma consulta repetitiva ao HP final. Golpes que cruzam o limite são cobertos pelo teste real de dano/apresentação.

A tentativa anterior já tinha trava por batalha e transporte único (`AudioStreamPlayer` + `AudioStreamSynchronized`). Não reproduzimos reinícios ou solicitações duplicadas espontâneas. Ela corrigia a perda de volume do crossfade antigo, mas calculava os volumes dos substreams em `_process()`.

**Defeito técnico reproduzido:** o mixer de `AudioStreamSynchronized` aplica um ganho constante por bloco, sem interpolar alterações do recurso. Assim, a curva aparentemente suave nos testes de propriedades vira uma escada na saída PCM. Com duas fontes constantes conhecidas (0,1 e 0,5), a implementação anterior produziu salto de **0,0066656768 entre amostras** no fade a 60 FPS. A nova configuração nativa produziu no máximo **0,0000211671** no teste correspondente, incluindo o início do fade. Os resultados medem a implementação, não provam que essa era toda a interferência ouvida pelo usuário.

Referências do motor oficial 4.7.2: [mixer sincronizado](https://github.com/godotengine/godot/blob/4.7.2-stable/modules/interactive_music/audio_stream_synchronized.cpp), método `AudioStreamPlaybackSynchronized::mix`; [mixer interativo](https://github.com/godotengine/godot/blob/4.7.2-stable/modules/interactive_music/audio_stream_interactive.cpp), métodos `_queue` e `_mix_stream`. O segundo aplica a rampa por amostra e para o stream anterior ao chegar a ganho zero.

As gravações aprovadas têm a mesma duração (87,200612 s) e correlação PCM de 0,962. Não foi demonstrada corrupção dos arquivos, silêncio no loop ou clipping nas fontes. O efeito `phase` dura 2 s; a percussão adicional faz parte do próprio arranjo aprovado `phase_two`. Esses elementos não foram removidos, filtrados ou substituídos para mascarar o relato. Se a trepidação persistir na gravação/pacote, essas fontes e o dispositivo/mixagem real precisam ser comparados por escuta antes de outra alteração.

## Implementação

- Um único player de combate passa a usar `AudioStreamInteractive`, com dois clips e crossfade nativo de 1,5 s, posição musical preservada e ganhos lineares complementares. Os recursos não têm BPM; nesse caso o parâmetro de duração do motor é em segundos.
- O mixer realiza a transição mesmo se `_process()` parar. Não há tween, timer ou reinício de player na troca de fase. A primeira faixa deixa de ser decodificada após o fade.
- A trava existente continua aceitando uma transformação por batalha. Reinício recria apenas o transporte, cancela o fade anterior e restaura a fase 1, preservando volume/mudo.
- Vitória, derrota e eventos tardios de título/pular são protegidos contra reativação da música. A sequência e os efeitos existentes permanecem preservados.
- `phase_mix` é somente progresso nominal para diagnóstico/compatibilidade; **não mede o ganho real do mixer**. O teste PCM e o clip nativo ativo validam o áudio de fato.
- `trace_music = true` ativa logs limitados a 512 registros: tempo, HP do modelo e visual, fase, faixa/clip, player, solicitações recebidas/aceitas e pedido/fim nominal do fade. O fim nominal não é apresentado como callback de conclusão do mixer. O harness de captura registra o estado real durante e após a transformação.

## Validação executada nesta entrega

Godot Linux **4.7.2 stable oficial** e templates da mesma versão, ambos conferidos com `SHA512-SUMS.txt` da distribuição oficial. Não foi utilizada a versão 4.6.3 preinstalada para os resultados desta entrega.

| Verificação | Resultado |
| --- | --- |
| Runner completo `tests/run_tests.py` | 18 suítes, **1.739 verificações**, zero falhas; mais 36 partidas completas, importação e startup de 120 frames |
| Música, dentro desse runner | **43 verificações**, os 12 cenários solicitados, zero falhas |
| Teste PCM | Fade nativo sem degraus de frame; avança sem `_process()`; chega ao segundo clip |
| Loop real | 92 s decodificados pelo mixer, com troca perto do final de 87,2 s; transporte ativo e menor RMS de bloco 0,0138793, sem bloco silencioso |
| Pacote Windows exportado, carregado isoladamente no motor Linux | **270 verificações**, **184 recursos**, zero falhas; os 63 cues são carregados |
| Preservação | **482 arquivos** protegidos comparados byte a byte sem mudanças; resultados das 36 partidas iguais à base, exceto duração da medição |
| Instrumentação optativa | Exercitada com reinício, pedido, conclusão nominal, estabilidade e evento após shutdown, sem erro |

O primeiro runner apontou um recurso ainda referenciado na saída do novo teste, embora todas as asserções passassem. O harness agora retorna da coroutine de teste antes de encerrar o motor, liberando as referências locais; o runner final encerrou sem esse erro. Não foram desativados checks ou ignoradas mensagens de erro.

A captura controlada instancia a cena real, aplica dano via API de combate para 451 HP e depois 450 HP, e deixa a timeline e o mixer de produção executarem. Não é uma partida manual completa. As gravações antes/depois incluem áudio gerado pelo modo Movie Maker; **não houve escuta humana nem captura de um dispositivo físico**. Não se afirma validação auditiva subjetiva nem compatibilidade de drivers reais.

## Distribuição

`Xardorok_Phase2_Windows_x64.zip` contém `Xardorok Boss Battle.exe`, `Xardorok Boss Battle.pck`, `LEIA-ME.txt` e `CREDITOS.txt`. O preset existente foi preservado. Os jogadores não precisam instalar Godot, Git ou Python. Arquivos e SHA-256 em `distribution_manifest.json`.

A exportação Windows release foi produzida com Godot 4.7.2. O PCK foi carregado fora do checkout em Linux; isso verifica os recursos exportados, **não equivale a executar o EXE no Windows**. Não há Windows/Wine disponível nesta máquina. A validação nativa desta correção está pendente. O workflow existente foi estendido à nova branch, com verificação SHA-512 e regressão musical no runner Windows, mas sua execução precisa ser confirmada separadamente. Resultados de Windows da tentativa anterior não são atribuídos a esta entrega.

## Reproduzir

```sh
GODOT=/caminho/Godot_v4.7.2-stable_linux.x86_64
python tests/run_tests.py --godot "$GODOT"
"$GODOT" --headless --path . --script tests/test_music_marco61.gd
"$GODOT" --headless --path . --export-release "Windows x64" "build/windows/Xardorok Boss Battle.exe"
# Em uma sessão gráfica; gravação controlada de 12,5 s, com áudio:
"$GODOT" --path . --fixed-fps 30 --quit-after 380 --write-movie /caminho/transition.avi --script tests/capture_phase2_audio.gd -- --trace=/caminho/trace.json
```

Os templates oficiais 4.7.2 devem estar instalados para exportar. A captura exige display gráfico; `--headless --write-movie` não serve nesta versão (renderer dummy sem textura). Foi usado Xvfb/OpenGL Mesa. Logs de teste e traces estão nesta pasta; os vídeos e o ZIP de jogadores são artefatos separados.

## Arquivos alterados

Produção: `scripts/audio/battle_audio.gd`. Testes: `tests/test_music_marco61.gd`, novo `tests/capture_phase2_audio.gd` e UID. Distribuição: `tools/distribution/validate_export.gd`, `tools/distribution/LEIA-ME.txt`. CI: `.github/workflows/windows-test-build.yml`. Evidências: esta pasta `docs/phase2/`.

Sem mudanças em combate, balanceamento, dados, IA, habilidades, animações, imagens, arena, câmera, HUD, fontes musicais, efeitos sonoros ou `project.godot`.
