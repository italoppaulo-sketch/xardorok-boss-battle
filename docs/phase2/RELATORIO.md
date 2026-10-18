# Fase 2 — música distinta, transição e Windows x64

Data: 18/10/2026. Base: `feature/marco-6-1-audio-fix-windows-export`, commit `cf201e68fb5802db4198f607c2ceeb5d631a7c62`, que inclui o Marco 6 completo e a tentativa anterior. Branch de trabalho: `fix/codex-phase2-audio-windows`. Sem merge automático.

## Diagnóstico principal e autorização da correção

O usuário descreveu um som sobreposto e trepidante, esclareceu que continuava por toda a segunda fase e, ao comparar os arquivos, relatou que a música inicial continuava enquanto entravam ruídos. A investigação mostrou que **não havia uma composição diferente para entrar**: `tools/audio/build_audio.py` montava `phase_two.ogg` como `music + extra`, usando a mesma gravação de `battle.ogg` com recortes de percussão. A correlação entre os arquivos era 0,962.

O transporte antigo efetivamente selecionava esse arranjo. Na captura antes da correção, a saída após o fade corresponde ao próprio arquivo `phase_two.ogg` (correlação 0,99649 no trecho de 8–11 s). Não foi demonstrada reprodução duplicada ou reinício espontâneo: havia um player, uma solicitação aceita e uma transformação. A música inicial percebida nesse caso estava **dentro da gravação da fase 2**, não necessariamente em outro player que continuava tocando. A tentativa anterior de corrigir apenas o crossfade não poderia transformar esse conteúdo em outra música.

Após essa explicação, o usuário escolheu expressamente **“Criar uma música distinta para a fase 2”**. Essa autorização permite a nova composição abaixo. Os arquivos aprovados anteriores, incluindo o arranjo rejeitado, foram preservados byte a byte; o catálogo passa a selecionar um novo arquivo. Não foi necessário remover efeitos existentes nem alterar o combate.

## Nova composição: A Coroa em Chamas

Peça instrumental original de **32 compassos, 150 BPM, Ré menor e 51,2 s**. Tem tema de metais, ostinato de cordas, ponte de oboé, baixo articulado, percussão acústica e reprise de trompete. Não usa trechos da música inicial nem o antigo stem de percussão recortada.

Foi composta por notas MIDI e renderizada localmente com **FluidSynth + FluidR3 GM**, licença MIT incluída nos créditos. A partitura MIDI, o renderizador reproduzível, a procedência e as métricas estão em `music/` e `tools/audio/compose_phase_two.py`. O PixVerse não tinha helper/executável instalado neste ambiente; não houve geração paga, pedido de credenciais ou uso de serviços externos para criar a faixa. O jogo continua reproduzindo OGG estático, sem dependências adicionais para jogadores.

O OGG decodificado tem pico de aproximadamente −5 dBFS, zero amostras saturadas e nenhum trecho silencioso de 100 ms. Sua correlação máxima medida com os primeiros 30 s do tema inicial é **0,042**, contra 0,962 do arranjo anterior. Na gravação final, o trecho de 8–11 s tem correlação **0,99825 com a nova faixa**, e apenas **−0,00585 com o tema inicial**. O trace confirma um player, uma transformação aceita e clip 1 estável. Isso demonstra a substituição efetiva do conteúdo musical após o fade; não equivale a aprovação auditiva humana.

## Controle musical e fragilidade secundária corrigida

Fluxo de produção: `Battle.deal_damage()` → `_update_boss_phase()` (fase 1, chefe vivo, HP <= 450) → evento `phase` → timeline da arena → `_apply_visual()` → `audio_event` → `BattleAudio.on_visual()`. O receptor acompanha o evento apresentado, não consulta continuamente o HP final para reiniciar música.

A tentativa anterior usava `AudioStreamSynchronized` e alterava ganhos em `_process()`. O mixer aplica esses ganhos por bloco, sem interpolação. Um teste PCM controlado reproduziu degraus de ganho de 0,0066657 entre amostras. Isso é uma fragilidade da transição, **não a explicação única do ruído persistente** relatado pelo usuário. Referências oficiais: [mixer sincronizado](https://github.com/godotengine/godot/blob/4.7.2-stable/modules/interactive_music/audio_stream_synchronized.cpp), `mix`; [mixer interativo](https://github.com/godotengine/godot/blob/4.7.2-stable/modules/interactive_music/audio_stream_interactive.cpp), `_queue` e `_mix_stream`.

Agora um único `AudioStreamPlayer` usa `AudioStreamInteractive`. O crossfade de 1,5 s é calculado por amostra no mixer, independentemente dos frames do jogo; o teste PCM mede salto máximo de 0,0000212. A composição distinta começa no início da frase, não na posição temporal arbitrária da música anterior. O primeiro clip é parado pelo motor ao completar o fade.

A trava por batalha aceita a transformação uma vez. Reinício cancela o transporte anterior, restaura fase 1 e preserva volumes/mudo. Vitória, derrota, título repetido e título tardio após pular não reativam trilhas indevidas. A ambiência também é parada explicitamente antes de reiniciar: um teste com muitos reinícios expôs retenção intermitente do decoder de `ruins.ogg`, identificada pelo log verbose. Após essa correção, três repetições de diagnóstico e o runner completo encerraram sem esse erro. Não foi inserido atraso na transição nem suprimida mensagem do runner.

`trace_music = true` ativa até 512 registros de tempo, HP visual/modelo, fase, faixa/clip, estado dos players, solicitações recebidas e aceitas. `phase_mix` e o evento `crossfade_nominal_end` são **diagnósticos nominais**, não leituras do ganho ou callbacks de conclusão do mixer. O clip ativo, a saída PCM e as capturas verificam a reprodução real.

## Testes finais desta versão

Godot Linux **4.7.2 stable oficial**, com editor e templates conferidos por SHA-512 da distribuição oficial.

| Verificação | Resultado |
| --- | --- |
| `tests/run_tests.py` | **18 suítes, 1.740 verificações**, zero falhas; mais 36 partidas completas, importação e startup de 120 frames |
| Regressão de música (incluída acima) | **44 verificações**, os 12 cenários pedidos, zero falhas |
| PCM nativo | Fade sem degraus de frame e progressão sem `_process()`; chegada ao clip 1 |
| Loops reais | Mais de 140 s decodificados, com troca junto à emenda da fase 1 e passagem pelo loop completo da nova fase 2; menor RMS de bloco 0,0236581 |
| Pacote Windows isolado, carregado no motor Linux | **271 verificações**, **185 recursos**, todos os 63 cues carregados, zero falhas |
| Gravação final | Cena real, HP 451 → 450 pela API de dano, transformação pela timeline, música nova efetivamente presente; zero amostras saturadas |
| Preservação | **481 arquivos protegidos** da base idênticos; todos os arquivos de áudio originais preservados; resultados das 36 partidas iguais, exceto duração da medição |

Cenários cobertos: início; 451 HP; 450 HP; golpe que ultrapassa o limite; eventos repetidos no mesmo frame; fase 2 estável; reinício durante/após fade; vitória durante/após fade; derrota; volume durante fade; mudo/desmudo. Também há proteção contra título repetido/tardio e eventos após shutdown.

As capturas são fixtures controladas da cena real, não partidas manuais completas. O modo Movie Maker grava imagem e áudio do mixer. Não houve escuta humana pelo agente nem conferência de áudio em dispositivo físico; portanto **não se declara eliminação perceptiva definitiva do defeito apenas pelos testes**. A nova composição e sua gravação são entregues para avaliação auditiva.

## Distribuição e Windows

`Xardorok_Phase2_Windows_x64.zip` contém `Xardorok Boss Battle.exe`, `Xardorok Boss Battle.pck`, `LEIA-ME.txt` e `CREDITOS.txt`. Não requer Godot, Git, Python, FluidSynth ou instalação adicional para jogadores. O preset existente permanece intacto; os recursos sonoros são importados no PCK. Hashes e tamanhos em `distribution_manifest.json`.

O PCK final foi validado fora do checkout em Linux. A validação nativa automatizada desta composição está registrada em `windows_ci.json`, com o commit e o run correspondente. O run anterior `39156773156`, do commit `3b2257f`, validou o controlador antes da composição nova e não é usado como prova da nova faixa. Não houve teste manual com janela, GPU e saída física de áudio no Windows. Os logs detalhados do GitHub exigem login; o estado dos jobs foi observado nas páginas públicas de execução.

## Reprodução

```sh
GODOT=/caminho/Godot_v4.7.2-stable_linux.x86_64
python tests/run_tests.py --godot "$GODOT"
"$GODOT" --headless --path . --script tests/test_music_marco61.gd
"$GODOT" --headless --path . --export-release "Windows x64" "build/windows/Xardorok Boss Battle.exe"
# Com display gráfico e templates correspondentes instalados:
"$GODOT" --path . --fixed-fps 30 --quit-after 380 --write-movie /caminho/transition.avi --script tests/capture_phase2_audio.gd -- --trace=/caminho/trace.json
```

Foi usado Xvfb/OpenGL Mesa para a gravação. `--headless --write-movie` não funciona com o renderer dummy desta versão. `music/README.md` explica como renderizar a partitura original. A atualização do gerador de catálogo mantém a nova seleção se o catálogo for reconstruído.

## Arquivos e revisão

Produção: `scripts/audio/battle_audio.gd`, `assets/audio/catalog.json`, novo `assets/audio/music/phase_two_distinct.ogg` e importação. Fonte musical: `tools/audio/compose_phase_two.py`, atualização de `tools/audio/build_audio.py` e arquivos de `docs/phase2/music/`. Testes: `tests/test_music_marco61.gd`, novo `tests/capture_phase2_audio.gd` e UID. Distribuição: `tools/distribution/validate_export.gd`, `LEIA-ME.txt`, `CREDITOS.txt`. CI: `.github/workflows/windows-test-build.yml`. Demais alterações são evidências desta pasta.

Sem alterações em balanceamento, HP/dano, IA, habilidades, animações, sprites, cenário, câmera, HUD, efeitos existentes ou `project.godot`. A mudança de identidade da faixa da fase 2 foi explicitamente autorizada pelo usuário após o diagnóstico.

A branch foi publicada, sem merge. `gh pr create --draft` foi bloqueado: `Post "https://api.github.com/graphql": Forbidden`; a conexão à API também retornou HTTP 403 no proxy. O acesso Git funciona. Foi salva no rascunho a inclusão de `api.github.com`, preservando os presets; essa gravação não aplica a rede. Para tentar criar o PR novamente, é necessário aplicar a alteração nas configurações do ambiente. Nenhum novo segredo foi solicitado. O título/corpo do PR estão preparados; base pretendida: `feature/marco-6-1-audio-fix-windows-export`; head: `fix/codex-phase2-audio-windows`.
