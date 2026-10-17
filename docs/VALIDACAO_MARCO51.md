# Validação — Marco 5.1

## Resultado

Godot **4.7.2.stable.official.ed1daf0bf**, Linux. A importação do editor, a inicialização da cena e **1.825 verificações funcionais** passaram sem falhas ou `ERROR:`. A renderização real OpenGL 4.5 / Mesa 25.2.8 / llvmpipe produziu **14 capturas, 45 verificações gráficas, zero falhas**, sem erros de shader.

| Suítes | Verificações | Falhas |
|---|---:|---:|
| Regressões aprovadas de combate, habilidades, iniciativa, percepção, cena, entradas e recursos do Marco 5 | 1.282 | 0 |
| Integridade dos nove PNGs e nove SpriteFrames aprovados | 18 | 0 |
| Textura vulcânica, máscara, continuidade e vínculo às células | 20 | 0 |
| Invocação, ocupação, visibilidade e seleção dos lacaios | 86 | 0 |
| Geometria, obstáculos e suporte do palco 3D | 251 | 0 |
| Câmera integrada, cliques, âncoras, agrupamentos e alternância | 168 | 0 |
| **Total funcional** | **1.825** | **0** |

As regressões antigas apontam explicitamente para `scenes/main_original.tscn`, preservando sua finalidade de testar a apresentação 2D aprovada. A nova suíte de câmera aponta para a cena principal integrada; a opção `--prototype` executa a mesma suíte na cena experimental isolada. As verificações posteriores de câmera substituem a contagem anterior de 113; não foram somadas como testes diferentes.

## Migração controlada

Antes de integrar a apresentação híbrida, a cena experimental `scenes/experimental/camera_lab.tscn` passou por testes de seleção, movimentação e ataques reais em nove combinações de ângulo e zoom. Os controles de arrasto e roda também foram executados. A cena experimental produziu capturas reais e concluiu uma partida completa com o mesmo controlador e motor de combate. Somente depois desse resultado a apresentação foi integrada à cena principal.

A apresentação original pode ser aberta diretamente em `scenes/main_original.tscn`, pelo argumento `--original-2d` ou alternada com **F2**. O teste de alternância comprova preservação da mesma instância do motor, células, HP, PM, ações e estados, incluindo reinício após voltar ao modo híbrido. Não há dois motores de combate.

## Câmera, seleção e agrupamentos

`test_camera_marco51.gd` executou os ângulos **−90°, 0° e +90°**, cada um com os fatores de distância **0,62 / 1,00 / 1,32**. Em todas as nove combinações, foram verificados projeção reversa, clique no corpo com transparência, seleção, movimentação por mouse, ataque por mouse, consumo real da ação, HUD fixo e preservação dos sprites 2D.

O teste verifica a coincidência da âncora dos pés com a célula lógica em cada combinação. Uma invocação real prepara Xardorok, um herói e dois lacaios agrupados em células válidas; a seleção pela pequena base de cada unidade é validada nas nove combinações de ângulo e zoom, totalizando 36 verificações de agrupamento. Os testes não exigem clicar através do corpo opaco de outra unidade: escolhem células visíveis, respeitando profundidade. Os retratos preservam acesso aos aliados encobertos.

Também foram executados limites de órbita/zoom, botão direito e arrasto, roda, botão central e arrasto, Home, F, ausência de gasto de ação pelos controles de câmera, fumaça em três ângulos, F2 e reinício.

## Evidência gráfica

`test_render_marco51.gd`: **12 capturas, 37 verificações, zero falhas**. Os arquivos finais foram capturados após a correção da âncora espacial dos sprites: três ângulos da mesma arena, dois extremos de zoom, lava orgânica, escudo, raio encadeado, resposta de meteoros, fumaça, vitória e derrota. O golpe de vitória e as habilidades dos cenários gráficos usam as regras reais; os posicionamentos isolados são fixtures, não partidas de balanceamento.

`test_spatial_effects_marco51.gd`: **8 verificações, zero falhas**, com mais duas capturas. Um incêndio assimétrico na célula **(6,2)** é comparado ao espelho seguro **(6,6)** no framebuffer. A média da diferença RGB em uma vizinhança de 7×7 pixels foi **0,28289** na célula perigosa e **0,00000** na segura. Após a extinção, a diferença foi **0,00000**. Essa comparação verifica a correspondência entre máscara, UV do piso 3D e células reais, sem inferi-la somente do código.

A manifestação de Dalamud também foi renderizada pelo evento real de suporte: um billboard espiritual com os recursos aprovados, buffs reais e nenhuma unidade física adicional.

Capturas em `docs/capturas/`:

- `marco51_arena_menos90.png`, `marco51_arena_zero.png`, `marco51_arena_mais90.png`.
- `marco51_zoom_perto.png`, `marco51_zoom_longe.png`.
- `marco51_lava_organica.png`, `marco51_lava_correspondencia.png`.
- `marco51_escudo.png`, `marco51_raio.png`, `marco51_meteoros.png`, `marco51_fumaca.png`.
- `marco51_vitoria.png`, `marco51_derrota.png`, `marco51_dalamud_espirito.png`.

## Partidas e preservação do balanceamento

A branch aprovada do Marco 5 foi extraída por `git archive` para uma pasta isolada. Isso impediu que alterações simultâneas contaminassem a referência. O Godot e as ferramentas foram reutilizados dos caches existentes, sem novo download ou instalação.

As **36 partidas completas**, com as mesmas doze políticas e sementes 17, 42 e 99, produziram **29 vitórias e 7 derrotas**, sem violações de integridade. O JSON foi idêntico, byte a byte, ao publicado no Marco 5: `SHA256 0948f25610a3132466884bd7623ff44362e050067cf9cc3d8d7efffe01d177f3`.

As regras em `scripts/combat`, `scripts/ai`, `scripts/abilities`, `scripts/data`, `scripts/support` e a estratégia de simulação não foram alteradas. O lote de referência não foi repetido depois de mudanças exclusivamente visuais. A opção `--skip-encounters` permite repetir somente as regressões nessas condições.

Uma partida completa adicional foi executada na apresentação híbrida, com política Antimagia e semente 17. A câmera variou entre sete orientações e três aproximações. O resultado real foi **GRUPO DERROTADO na rodada 12**, sem falhas de execução, igual ao ensaio visual do Marco 5. O resultado não foi adulterado e não integra a contagem das 36 partidas. Sua captura é `marco51_partida_completa.png`.

## Demonstração

[Vídeo técnico da câmera](demos/marco51_camera.mp4): **18 segundos, 270 frames, 15 fps, 1200×700**, codificado a partir do viewport real. A estratégia Antimagia, semente 17, executa combate de produção enquanto a câmera orbita e aproxima. Foram registradas **37 decisões de heróis**, chegada à rodada **4** e redução real de HP do chefe de **900 para 347**, sem modificar HP, recursos ou dano. `Engine.time_scale = 1.5` acelera a apresentação; a codificação a 15 fps não é uma medição de desempenho do jogo. O vídeo não é uma partida completa nem um filme cinematográfico. A dica de controles da câmera foi reposicionada após a gravação para evitar sobreposição com a inspeção de alvos; as capturas estáticas finais mostram essa correção.

## Reprodução

```bash
python tests/run_tests.py --godot /caminho/Godot_v4.7.2-stable_linux.x86_64
# Para repetir apenas as regressões quando as regras permanecem inalteradas:
python tests/run_tests.py --skip-encounters --godot /caminho/Godot_v4.7.2-stable_linux.x86_64
# Requer display gráfico real:
godot --path . --rendering-method gl_compatibility --script tests/test_render_marco51.gd
godot --path . --rendering-method gl_compatibility --script tests/test_spatial_effects_marco51.gd
godot --path . --rendering-method gl_compatibility --script tests/test_match_visual_marco51.gd
```

O gerador opcional `test_demo_camera_marco51.gd` salva frames em `user://marco51_demo_frames`, ou no diretório definido por `XARDOROK_DEMO_FRAMES`. O vídeo foi codificado com FFmpeg; arquivos temporários e ferramentas não fazem parte do projeto.

## Limitações

Windows e exportação executável não foram testados. As imagens aprovadas oferecem uma perspectiva corporal; billboarding mantém os sprites voltados à câmera e não cria vistas laterais ou posteriores. Unidades ou chão encobertos exigem outro ângulo, zoom ou retrato; os testes não prometem seleção através de obstáculos. Aproximações extremas podem cortar partes da arena, recuperáveis por Home. A referência vulcânica é uma imagem estática e sua resolução limita a nitidez em ampliações fortes. Revisão artística, ergonomia e desempenho em hardware do usuário ainda exigem validação manual.
