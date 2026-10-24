# Relatório breve — Marco 6A

## Entrega efetiva

Uma música instrumental em OGG com **75,000 s**, cinco efeitos independentes em WAV e uma página local de audição. O pacote de fontes inclui o WAV de avaliação, o MP3 musical completo de aproximadamente 88,45 s, os cinco MP3 dos efeitos, prompts, proveniência e receita de edição. Não foram produzidas outras faixas.

## Base e preservação

Inspeção do GitHub em 18/10/2026: o Marco 5.2 mais recente está em `feature/marco-5-2-combat-refinement`, commit **`2db39f1a0f600e7e5cfc4a6d269d06c03ca90aa4`**, com PR #6 aberto e não incorporado. O Marco 5 original permanece em `b437d480c37b3834aa944b15c4e95385d567832d`; `main` está em `6ab02bd3595ec8e9495fd9b7793e802248d26b98`. Não existe registro de merge/aprovação formal do PR #6 no GitHub. A base 5.2 é a última entrega deste chat, adotada sem modificar seus arquivos.

A branch independente é `feature/marco-6a-audio-prototype`, criada diretamente de `2db39f1…`. Somente `audio/prototype_6a/` foi acrescentado. Scripts, cenas, sprites, arena, câmera, projeto e regras de combate foram preservados. `.gdignore` isola a pasta de demonstração da importação automática do Godot. Não há AudioStreamPlayer, autoload, bus, chamada ou referência adicionada ao jogo. A batalha continua sem esta trilha até sua aprovação.

## Ferramentas e processamento

- Serviço de geração musical Runway: uma geração instrumental, Lyria 3 Pro, sem áudio de terceiros enviado como input.
- Runway Sound Effects: cinco gerações separadas, com texturas e durações próprias.
- FFmpeg/ffprobe: decodificação, edição de duração, fade, normalização, exportação e medições. Python 3 coordena a receita sem gerar notas por código.
- GitHub: branch e PR para revisão, sem merge automático.
- Foram reportados **21 créditos consumidos**: 8 pela música e 13 pelos cinco efeitos (2 + 3 + 3 + 4 + 1). Nenhuma segunda proposta ou regeneração paga foi executada. Processamento local não chama o serviço.

## Verificações realmente executadas

Todos os seis arquivos de audição foram decodificados por FFmpeg. Duração, canais, taxa de amostragem, loudness e true peak foram medidos; seus hashes e os do WAV musical estão em `sources/audio_metrics.json`.

| Render | Duração | Formato | LUFS integrado | True peak |
| --- | ---: | --- | ---: | ---: |
| Música WAV, pacote de fontes | 75 s | PCM 24 bits / 44,1 kHz / estéreo | −16,00 | −3,63 dBTP |
| Música OGG | 75 s | Vorbis / 44,1 kHz / estéreo | −16,02 | −3,46 dBTP |
| Martelo de Grosso | 2 s | PCM 16 bits / 44,1 kHz / estéreo | −14,78 | −2,68 dBTP |
| Fushigiri | 3 s | PCM 16 bits / 44,1 kHz / estéreo | −10,65 | −2,56 dBTP |
| Raio de Thuxil | 3 s | PCM 16 bits / 44,1 kHz / estéreo | −19,26 | −2,96 dBTP |
| Meteoro | 4 s | PCM 16 bits / 44,1 kHz / estéreo | −17,67 | −2,47 dBTP |
| Laser dos acólitos | 1 s | PCM 16 bits / 44,1 kHz / estéreo | −13,18 | −2,85 dBTP |

Não foram detectados picos acima de 0 dBTP nos renders. Os efeitos não foram igualados em LUFS, para preservar suas diferenças de impacto; LUFS de sons tão curtos não equivale a percepção de volume. A música mantém faixa de loudness de aproximadamente 8,5 LU, sem esmagar toda a dinâmica. Verificações de duração, estéreo, sinal não silencioso, limites de pico e hashes distintos passaram durante a preparação.

Uma estimativa exploratória de periodicidade por autocorrelação deu aproximadamente 152 BPM. Não é uma transcrição confiável: **148 BPM, Ré menor e 4/4 são o briefing, não valores musicais certificados do áudio gerado**. A avaliação de melodia, expressividade, naturalidade dos timbres e adequação ao jogo cabe à audição do usuário; as medições técnicas não provam esses critérios artísticos. Não se declara escuta humana ou comparação com um catálogo de músicas.

Godot **4.7.2.stable.official.ed1daf0bf**, reutilizado do cache existente: importação headless do editor e inicialização da cena principal por 60 frames concluídas sem erros. A suíte de combate não foi repetida neste marco de arquivos de áudio: nenhuma regra ou referência do jogo foi alterada. Não atribuímos os números dos testes do Marco 5.2 a esta etapa.

## Limitações e próxima decisão

- Fonte do gerador em MP3; o WAV convertido não é uma nova captura sem perdas. OGG é o formato compacto de avaliação no repositório.
- Sem MIDI, partitura, stems por instrumento ou sessão de DAW nativa retornados pelo serviço. Prompts, mix original e edição são as fontes disponíveis.
- Sem loop final, transições dinâmicas de fase, mix com habilidades simultâneas, ambiência ou testes em alto-falantes/fones físicos realizados por uma pessoa.
- Condições de uso e ausência de garantia de exclusividade documentadas em `ORIGEM_E_LICENCAS.md`.
- Aprovação artística pendente. Só depois dela devem ser refinados arranjo, loop e volumes dentro do combate.
