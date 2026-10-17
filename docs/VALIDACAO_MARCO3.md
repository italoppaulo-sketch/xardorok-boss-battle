# Marco 3 — implementação e validação

Data: 17/10/2026. Base oficial preservada: Marco 2, commit `52dd9cf857216828191e45b3d9bbca0cff0dbba4`. Branch de entrega: `feature/marco-3-visual`. O PR tem como base `feature/marco-2`, porque o PR do Marco 2 ainda está aberto; nenhuma alteração é incorporada automaticamente à `main`.

## Implementado

- Cinco heróis, Xardorok da segunda forma e acólitos em PNG com alfa e AnimatedSprite2D/SpriteFrames. Repouso, caminhada, dois ataques, conjuração, reação, esquiva, queda e especial usam poses distintas. Total: 232 quadros corporais, incluindo oito poses aladas do espírito Dalamud.
- Proporções e detalhes registrados em [REFERENCIAS_VISUAIS.md](REFERENCIAS_VISUAIS.md). Grosso mantém o corpo descoberto; o gelo é temporário. Cassandra conjura com as mãos. Thuxil preserva a cabeça dracônica de bronze e a gola clara.
- Nove famílias de efeitos com quatro quadros cada; projéteis, cortes, conexões elétricas, cura, fumaça, meteoros e laser. Preparação, emissão e impacto são agendados por eventos; a camada visual não aplica dano nem consome ações.
- Os dois golpes físicos usam poses e impactos separados. Fushigiri tem corte sombrio e feedback de custo de HP. Voo, duplicata, gelo temporário, crescimento, dano, crítico, esquiva e derrota estão conectados ao estado real.
- Lacaios agora são magos encapuzados com laser vermelho real: alcance 6, dano arcano 14, ação principal, dependência de visão e bloqueio por silêncio. A alternativa física permanece quando silenciados; HP, limite de três e início de atuação na rodada seguinte são preservados.
- Piso modular nas mesmas 15 × 9 células do motor, com 131 livres e os mesmos quatro obstáculos. Pilares são posicionados nas células bloqueadas. Braseiros, cristais, correntes e trono ficam fora dos caminhos; ordenação visual pelos pés, luz ambiente e fundo distante sem piso falso.
- Comandos de combate ficam temporariamente bloqueados durante a apresentação; reinício permanece disponível. Barras da arena acompanham os impactos e o painel reconcilia o estado ao fim da sequência.
- Dalamud surge translúcido, luminoso e flutuante pelo ponto de integração de buffs já existente, sem HP, ocupação, colisão ou turno. Nenhum botão ou regra nova de invocação foi inventado.

## Ambiente executado

Godot **4.7.2 stable oficial**, Linux x86_64, build `ed1daf0bf`. Renderização gráfica GL Compatibility/OpenGL 4.5 com Mesa llvmpipe em display X11 virtual de **1200 × 700**. Os testes gráficos leram o framebuffer do motor real; não usaram o renderizador dummy do modo headless.

## Resultados executados

| Verificação | Resultado |
| --- | --- |
| Importação/compilação `--headless --editor --quit` | Sem erros |
| `test_battle.gd` | 22 verificações, nenhuma falha |
| `test_abilities.gd` | 119 verificações, nenhuma falha; todas as habilidades do Marco 2 |
| `test_scene.gd` | 46 verificações, nenhuma falha; menus, gigante, cura, resultados e reinício |
| `test_input.gd` | 18 verificações, nenhuma falha; mouse/teclado enviados ao viewport e limites da interface |
| `test_visuals.gd` | 377 verificações, nenhuma falha |
| `test_encounters.gd` | 20 partidas completas, sementes 17–36: 20 vitórias, nenhuma falha de integridade |
| Cena principal por 120 frames headless | Sem erros |
| `test_render.gd`, com display/OpenGL | 22 cenários de habilidades renderizados, nenhuma falha |
| `test_showcase.gd`, com display/OpenGL | Cinco capturas reais; partida completa desde posições/HP/recursos originais: vitória na rodada 4, nenhuma falha |
| `gdlint`, `gdformat --check`, `git diff --check` | Sem problemas |

As quatro suítes históricas somam 205 verificações explícitas, além das 377 novas: **582 verificações**. As partidas validam limites de HP/PM, ações, estados, células ocupadas, obstáculos e quantidade de lacaios. Os testes unitários de valores exatos desativam rolagens; as partidas completas usam sementes reproduzíveis.

A suíte visual verifica importação, alfa, margem transparente, âncora de todos os quadros, poses distintas, nomes das animações, queda sem loop, proporção de Grosso, piso, props e ordenação. Também mede HP visual antes/depois do impacto, ausência de dano duplicado, bloqueio de turno durante animação, cancelamento pelo reinício, laser real com custo de ação, silêncio e espírito sem unidade física adicional. Comparar hashes garante quadros diferentes; a inspeção das folhas/capturas complementa essa verificação para avaliar poses e fidelidade.

Os testes de interface foram adaptados para aguardar a nova apresentação antes do comando seguinte. A estratégia das partidas é compartilhada entre o teste lógico e o gráfico em `tests/support/autoplayer.gd`; ela não participa da IA do jogo. A partida gráfica roda com tempo de apresentação acelerado em quatro vezes, sem alterar HP, recursos ou regras. As capturas de efeitos usam cenários controlados com posições ajustadas; a captura de vitória vem da partida completa sem esses ajustes.

## Capturas do jogo

| Arquivo | Origem |
| --- | --- |
| [Batalha](capturas/marco3_batalha.png) | Cena principal, posições iniciais e interface 1200 × 700 |
| [Fushigiri](capturas/marco3_fushigiri.png) | Habilidade real, pose/corte, dano e custo de HP |
| [Laser](capturas/marco3_laser.png) | Dois magos encapuzados; emissão/impacto vermelho e dano real de 14 |
| [Dalamud](capturas/marco3_dalamud.png) | Ponto de integração espiritual e buffs, sem combatente adicional |
| [Vitória](capturas/marco3_vitoria.png) | Fim da partida completa renderizada, rodada 4 |

As capturas são PNGs obtidos do viewport do Godot, não ilustrações conceituais. Não foi produzido vídeo cinematográfico.

## Reproduzir

Abra `project.godot` no Godot 4.7.2, espere a importação e pressione F5. Consulte o README para trocar a branch no GitHub Desktop. Execute `python tests/run_tests.py --godot CAMINHO_DO_GODOT` para as suítes headless. Para conferir gráficos e recriar as capturas, execute, sem `--headless`, `godot --path . --script tests/test_render.gd` e `godot --path . --script tests/test_showcase.gd`.

## Limitações e revisão necessária

- Executado no Linux/OpenGL por software; não foi testado no Windows, em GPU física, em outras resoluções ou como exportação executável. O aviso do driver sobre V-Sync não suportado apareceu; não houve erro de script ou de shader nos testes finais.
- Sprites v1 integrados aguardam revisão artística do usuário. Nenhuma aprovação definitiva de identidade é presumida. A pixel art é amostrada por nearest, com pequenos detalhes sujeitos a refinamento manual.
- Não existe retrato original específico da segunda forma de Xardorok; sua transformação segue a descrição autorizada. O retrato de Thuxil não mostra as pernas e o grupo corta parte dos pés; essas partes têm conclusão neutra documentada. Lacaios seguem a definição textual autorizada.
- O voo reutiliza as poses especiais com oscilação e iluminação; não há movimento em oito direções nem atlas específico para cada direção. Direção horizontal usa espelhamento. O gigante preserva a célula lógica, de modo que o sprite pode se sobrepor visualmente a células vizinhas sem atravessar obstáculos mecanicamente.
- O espírito tem poses de asas/bênção e transições de aparição, mas sua invocação pelo jogador e a sequência cinematográfica completa continuam futuras, conforme o escopo. Não há áudio nesta entrega.
- O laser muda a ameaça dos lacaios para alcance mágico. Os 20 resultados positivos são evidência de funcionamento, não garantia de balanceamento para todas as estratégias. As regras e a IA contextual de Xardorok permanecem as do Marco 2.
- O teste gráfico automatizado confirma execução/frame e interações; avaliação subjetiva final de fluidez e fidelidade cabe à revisão no computador do usuário. A folha modular inclui peças reservadas, listadas no pipeline; não se alega que todas apareçam simultaneamente na arena.
