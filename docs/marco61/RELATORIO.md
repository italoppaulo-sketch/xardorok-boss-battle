# Marco 6.1 — transição musical e Windows x64

Base: Marco 6 aprovado, commit `1affb6ef36e373e941231d4b9c2132a9d272f85d`. Branch: `feature/marco-6-1-audio-fix-windows-export`. Sem merge automático.

## Correção

O crossfade anterior suavizava separadamente o volume de cada player em dB, partindo de −80 dB na segunda faixa. A primeira faixa diminuía enquanto a segunda ainda estava quase inaudível. A transformação também aplicava ducking de −7 dB durante o mesmo intervalo. Na reprodução instrumental anterior, a soma dos ganhos dos players chegou a **−13,76 dB**, nas amostras registradas do intervalo de transição. Não foi reproduzido disparo duplicado pela IA nesse caso, mas o receptor de áudio não tinha proteção explícita contra notificações repetidas.

Agora, um único `AudioStreamPlayer` usa `AudioStreamSynchronized` para as duas gravações aprovadas. Início e posição de reprodução compartilham um transporte. O crossfade de 1,5 segundo usa ganhos lineares complementares com curva suave, sem o atraso de subida desde −80 dB e sem ducking adicional provocado pela transformação. As faixas são arranjos correlacionados da mesma melodia, por isso não foi aplicada uma curva de potência constante que aumentaria seu nível no meio da passagem. O ducking dos ataques continua separado e suavizado.

Uma trava por batalha aceita a transição uma vez; notificações repetidas e eventos após encerramento são ignorados. Reiniciar limpa a trava, o fade, ducking, música de resultado e transporte anterior. Volumes e mudo permanecem como escolhas do usuário.

**Preservação:** 464 arquivos protegidos da base comparados byte a byte, sem alterações: recursos de áudio e imagens, combate, IA, dados, habilidades, efeitos visuais, arena, câmera, `main.gd` e `project.godot`. O único módulo de produção modificado é `scripts/audio/battle_audio.gd`. Nenhuma gravação aprovada foi substituída ou regenerada.

## Testes executados

| Verificação | Resultado |
| --- | --- |
| Regressão completa no Godot 4.7.2/Linux | 1.696 verificações, zero falhas; inclui 211 de áudio e 21 dos controles de áudio |
| Lote de balanceamento | 36 partidas completas, zero falhas de integridade; resultados em `balance_regression.json` |
| Teste novo de música | 317 verificações, zero falhas: ganho durante fade, eventos repetidos, transporte único, reinício, mudo, volume, derrota, shutdown e passagem real pelo limite do loop |
| Pacote exportado em diretório isolado, Linux | 270 verificações, 184 recursos carregados, zero falhas |
| Windows nativo no GitHub Actions | Exportação oficial release, inicialização do `.exe` e validação do PCK: 270 verificações, 184 recursos, zero falhas |
| Partida audiovisual real em Linux/OpenGL | Vitória na rodada 7, 377 cues, 4.102 frames a 30 FPS, uma transição musical, zero falhas |
| Lint GDScript e diff | Sem problemas |

Os testes do pacote verificaram todos os recursos exportados de imagem, fonte e áudio; os 63 cues; entrada real de M e Espaço; limite exato de 450 HP e dano direto de 900 para 400 HP; dez notificações duplicadas; reinício com volume/mudo; derrota; cinematografia, título, coroa e fanfarra; e limpeza ao pular/reiniciar. O `.exe` foi iniciado com `Start-Process -Wait`, fora da pasta de checkout, e encerrou com sucesso. Os testes mais extensos do PCK foram executados pelo console oficial do Godot no mesmo runner Windows, com um harness externo; esse harness não é distribuído aos jogadores.

Na partida gravada, Xardorok passou de **475 para 432 HP** por um golpe de 43. O áudio recebeu a transformação em **49,26 s**, uma única vez para a música. Vitória e fanfarra ocorreram normalmente. O efeito sonoro chamado `phase` também é utilizado em outros momentos de impacto/encerramento; sua repetição no trace não representa reinício da música. Veja `full_match.json` e o trecho audiovisual entregue.

O teste de loop buscou a posição 0,2 s antes do final e confirmou que o transporte continuou tocando e retornou ao começo. As durações das duas gravações são iguais e ambas usam loop no mesmo transporte.

## Distribuição

`Xardorok_Marco6_1_Windows_x64.zip` contém somente:

- `Xardorok Boss Battle.exe` — template oficial Windows x86_64 release do Godot 4.7.2.
- `Xardorok Boss Battle.pck` — recursos e scripts compilados necessários ao jogo.
- `LEIA-ME.txt` — inicialização e controles.
- `CREDITOS.txt` — créditos, licença MIT do motor, fonte e avisos de terceiros.

Não inclui editor, fontes soltas do projeto, testes, documentação de desenvolvimento, caches de trabalho, credenciais ou instaladores. Os recursos importados que o Godot precisa em execução ficam dentro do PCK. O preset mantém o PCK externo; os dois arquivos devem permanecer juntos.

O ZIP entregue foi recuperado do build Windows bem-sucedido, sem modificar seu conteúdo. Tamanho: **50.169.637 bytes**. SHA-256: `c2eb215a2fdd5d2c281d24e14e76cf6b4d61a20114bfaf856424bf1d7b3a5b8e`. Hashes individuais em `distribution_manifest.json`.

[Build e logs Windows](https://github.com/italoppaulo-sketch/xardorok-boss-battle/actions/runs/39152316930) · [Artefato de teste](https://github.com/italoppaulo-sketch/xardorok-boss-battle/actions/runs/39152316930/artifacts/12145363878)

O artefato desse run foi gerado do commit `52e055e…`; as alterações posteriores deste marco acrescentam somente testes, evidências e documentação. Os arquivos de produção e o preset do ZIP correspondem à versão final. Retenção do artefato: até 17/11/2026. Não foi publicada uma versão definitiva.

## Limitações

A validação Windows foi **nativa e automatizada, sem janela e sem saída física de áudio**. Ainda é necessário conferir visualmente e ouvir o jogo em um PC Windows com drivers reais. Isso inclui compatibilidade de GPU, DPI, dispositivos de áudio e interação manual. A apresentação e a mixagem reais foram exercitadas em Linux/Mesa pela gravação do Godot, não por Wine. Não se declara validação audiovisual humana no Windows.

Em Linux, o encerramento abrupto por `--quit-after` em um teste de inicialização emitiu avisos de recursos de áudio ainda em uso. Os testes com shutdown e espera, a partida gravada e os logs Windows anexos encerraram sem esses erros. Essa diferença de encerramento fica registrada; não foi tratada como falha silenciosamente aprovada do teste funcional.

O executável de teste não possui assinatura digital. Requisitos de referência: Windows 64 bits e OpenGL 3.3. Não requer Godot, Python ou Git instalados. As configurações de áudio são armazenadas em `user://`, fora de qualquer caminho local do desenvolvedor.

## Reproduzir

```sh
python tests/run_tests.py --godot CAMINHO_DO_GODOT_4_7_2
godot --headless --path . --script tools/distribution/validate_export.gd
godot --headless --path . --export-release "Windows x64" "build/windows/Xardorok Boss Battle.exe"
godot --path . --write-movie gameplay.avi --fixed-fps 30 --script tests/capture_marco61.gd
```

Instale os templates oficiais correspondentes antes de exportar. O workflow `.github/workflows/windows-test-build.yml` automatiza a exportação, inicialização isolada, validação e publicação de um artefato temporário, sem release ou merge.
