# Marco 6 — Identidade sonora integrada

Base jogável: Marco 5.2, `2db39f1a0f600e7e5cfc4a6d269d06c03ca90aa4`.
Branch: `feature/marco-6-complete-audio`. Sem merge automático.

Abra `project.godot` no Godot 4.7.2 e pressione F5. A batalha já inicia com música e ambiência. **F10** abre os volumes de Geral, Música, Efeitos, Ambiência e Interface; cada categoria tem mudo independente. **M** alterna o mudo geral. Preferências ficam em `user://audio.cfg` e sobrevivem ao reinício da batalha. Os controles de combate e câmera permanecem os aprovados.

## O que está integrado

- Trilha de batalha em loop e variação alinhada da fase 2, preservando exatamente a melodia. A variação acrescenta uma performance de percussão gerada separadamente, editada em acentos associados aos ataques rítmicos do próprio tema; não é outra melodia desconectada.
- Fanfarra de vitória e tema breve de derrota, ambos novos e instrumentais.
- 63 entradas de áudio, incluindo habilidades, armas, estados, passos, interface, magias, meteoros e acólitos. Famílias coerentes são reutilizadas para eventos gerais.
- Novo martelo físico, separado do encantamento glacial e dos estilhaços de gelo. Novo corte Fushigiri: preparação, lâmina, ruptura sombria e sacrifício de HP discreto. Os dois arquivos rejeitados no Marco 6A não foram usados.
- Sons associados à apresentação dos eventos reais: contatos, dois golpes, saltos elétricos, projéteis, fases e retirada dos mortos.
- Limite de 14 vozes de efeitos/interface, prioridade para eventos fortes, variação de pitch limitada a ±1,5% nos efeitos, RNG independente do combate e redução temporária da música para Fushigiri/meteoros.
- Ambiência discreta de ruínas e presença de aura somente enquanto o efeito está visualmente ativo e o chefe vivo.

## Vitória BOSS DEFEATED

O último ataque termina sua apresentação antes de iniciar a sequência. A música de combate perde intensidade, há ressonância de queda, contato da coroa em **1,00 s** e entrada da fanfarra junto à revelação de **REI DAS CINZAS DERROTADO**, em **1,05 s**. A apresentação foi estendida de 3,6 para **7,2 s** para acomodar a frase de seis segundos e sua cauda. Isso não altera turnos, HP ou resultado. Pular cessa a fanfarra e efeitos; reiniciar limpa tudo e volta à música de batalha.

## Organização

`assets/audio/music/`, `sfx/heroes/`, `sfx/boss/`, `sfx/minions/`, `sfx/combat/`, `sfx/ui/` e `ambience/` contêm os renders. `assets/audio/catalog.json` centraliza caminhos, buses, prioridade e deduplicação. `scripts/audio/` possui o reprodutor e painel; `tools/audio/build_audio.py` contém a edição reproduzível das fontes.

Os buses Master, Music, SFX, Ambience e UI são criados em execução. Master tem limiter com teto de −1,5 dB. Não é necessário instalar um plugin para jogar.

## Evidência e reprodução

Veja [matriz completa](MATRIZ_AUDIO.md), [validação](VALIDACAO_MARCO6.md), [origens e condições de uso](FONTES_E_LICENCAS.md), [proveniência dos pedidos](PROVENIENCIA.json), [medidas dos arquivos](audio_metrics.json) e [trace audiovisual executado](capture_executed.json).

```sh
python tests/run_tests.py --godot CAMINHO_DO_GODOT
godot --path . --script tests/test_audio_ui_marco6.gd
godot --path . --rendering-method gl_compatibility --write-movie gameplay.avi --fixed-fps 30 --script tests/capture_audio_marco6.gd
```

O último comando grava imagem e áudio do próprio motor. A demonstração entregue é uma partida completa controlada por bot, política agressiva/semente 42; não altera HP, mana, iniciativa ou RNG após a semente inicial. O vídeo foi entregue separadamente para evitar incorporá-lo ao histórico git. A conversão para MP4 apenas comprime a gravação nativa; não adiciona efeitos por fora do jogo.
