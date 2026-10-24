# Validação — Marco 5.2

O desenvolvimento partiu exclusivamente do Marco 5 aprovado: **`b437d480c37b3834aa944b15c4e95385d567832d`**, branch `feature/marco-5-polish`. A branch de trabalho é `feature/marco-5-2-combat-refinement`. Não houve merge, cherry-pick ou cópia de arquivos do Marco 5.1. A publicação é para revisão; nenhuma incorporação automática à base foi autorizada.

## Ambiente efetivamente utilizado

Godot **4.7.2.stable.official.ed1daf0bf**, Linux, GDScript. Executável reextraído do ZIP já existente, sem download nem instalação de outra versão. Testes gráficos: Xvfb 1200 × 700, Compatibility/OpenGL, Mesa llvmpipe. Ferramentas e bibliotecas foram reutilizadas do cache. O aviso do driver sobre V-Sync não suportado não é erro de script ou renderização.

A arena continua sendo Node2D com sprites e câmera Camera2D. Uma busca em scripts/cenas de produção não encontrou Camera3D, Sprite3D, AnimatedSprite3D, Node3D ou MeshInstance3D. A comparação contra o commit-base não registra mudança nos PNGs aprovados dos personagens, nos SpriteFrames, nem nas referências de Dalamud. A nova imagem de referência vulcânica foi adicionada separadamente.

## Resultado dos testes

**1.464 verificações funcionais, zero falhas**, incluindo o teste de máscara do terreno. A contagem não inclui as verificações de integridade repetidas durante as 36 partidas. Importação, inicialização e encerramento do projeto também executados sem erros de scripts.

| Suíte | Verificações | Resultado |
| --- | ---: | --- |
| test_battle | 24 | 0 falhas |
| test_marco4 | 411 | 0 falhas |
| test_marco5 | 89 | 0 falhas |
| test_visibility_marco5 | 46 | 0 falhas |
| test_abilities | 122 | 0 falhas |
| test_scene | 46 | 0 falhas |
| test_input | 28 | 0 falhas |
| test_input_marco5 | 11 | 0 falhas |
| test_visuals | 496 | 0 falhas |
| test_presentation_marco5 | 9 | 0 falhas |
| test_marco52 | 92 | 0 falhas |
| test_input_marco52, headless | 53 | 0 falhas |
| test_terrain_marco52 | 27 | 0 falhas |
| test_victory_marco52, headless | 10 | 0 falhas |

No viewport gráfico real, `test_input_marco52` executou **56 verificações sem falhas**. Inclui entrada real de mouse e teclado, zoom suave/limites, HUD fixo, movimento após zoom, F/Home, clique sobre sprites sobrepostos, popup, Tab, Esc, Enter, cura, magia ofensiva, exclusão de inimigos encobertos e mortos, dissipação dos lacaios, nova invocação e botões de reação sem bônus/PM. `test_victory_marco52` executou **11 verificações gráficas sem falhas**: golpe final, projeção da coroa com zoom e pan, escala, faixa aprovada, pular e reiniciar. Total: **67 verificações gráficas**. Os testes de terreno produziram adicionalmente três capturas comparáveis, sem falhas.

Uma partida completa foi executada na cena principal com apresentação gráfica real, política `antimagia`, semente 17, sem alterar unidades ou resultados. Resultado observado: **GRUPO DERROTADO, rodada 15, zero falhas de execução**. A velocidade visual foi acelerada durante esse teste, sem alterar as regras. A derrota foi preservada como evidência; não foi substituída por uma vitória forçada. Vitória foi verificada separadamente por golpe final em fixture controlada.

## Regras e casos extremos verificados

- Invocação inicial permanece obrigatória quando não há impedimento legítimo. Silêncio continua impedindo conjuração; a IA tenta novamente depois. Reposição recebe prioridade abaixo de dois lacaios vivos, respeitando recarga de três turnos próprios e limite simultâneo de quatro.
- Lacaios têm 90 HP e dano base 14. Navegam por passos adjacentes, procuram linha de tiro a distância, evitam obstáculos, ocupação e fogo quando existe alternativa, e disparam laser no mesmo turno se a posição permite.
- Invocações não ocupam células vivas existentes. A morte libera a célula e remove o índice da iniciativa imediatamente. A apresentação dissipa o nó depois do curto intervalo visual. Os índices de dados permanecem estáveis como registros de HP zero para proteger os eventos pendentes; não são alvos, ocupantes nem atores de iniciativa.
- Remoção de um lacaio antes, depois e exatamente no cursor da iniciativa não pula o próximo combatente. Invocar novamente não recria o nó morto; usa um índice novo. Reinício elimina todos os resíduos.
- Cada herói começa com uma Reação Defensiva (RD). Só o início de uma nova rodada a renova; atualizar o turno individual não concede RD extra.
- **Defender:** 1 RD, sem ação bônus e sem PM; permanece no local e reduz o dano de meteoro em 50%. Não compromete a principal. O incêndio no piso continua possível.
- **Evadir:** 1 RD, deslocamento de até duas células até pouso válido fora de todas as marcas. Se o herói está no próprio turno com principal disponível, ela é consumida agora. Fora do turno ou depois de agir, fica comprometida a próxima principal. A mesma evasão não cobra as duas formas de custo.
- Duas evasões distintas, em rodadas diferentes antes de um próximo turno, geram dois compromissos e cobram uma ação por turno até quitar. Não apagam um débito anterior nem cobram duas vezes a mesma evasão.
- Sem RD não há evasão/defesa; não reagir preserva RD e recebe impacto integral. Múltiplos heróis respondem individualmente. Não há novo turno completo ou renovação de recursos na janela.
- Enraizamento, congelamento, ocupação, obstáculos, marca sobreposta, fumaça, mudança de fase, morte do chefe, bloqueio do avanço de iniciativa, ausência de dano duplicado e reinício permanecem cobertos pelas suítes aprovadas e novas.
- Escudo, aura ativável, fumaça, antimagia, habilidades dos cinco heróis, raio encadeado, críticos, esquiva, fogo ambiental, vitória e derrota continuam sendo regras reais, não efeitos cosméticos.

## Ajustes necessários nos testes históricos

Somente expectativas revogadas pelo pedido foram adaptadas. Flecha de gelo continua causando 38 nos lacaios: agora restam 52 de seus 90 HP, em vez de 22 de 60. O raio crítico continua causando 75: agora restam 15, em vez de eliminar automaticamente um lacaio com 60. Não se aumentou o dano para satisfazer o teste antigo. O teste contextual de distância do chefe passou a bloquear a invocação na sua fixture, pois a nova prioridade de reposição seria a escolha correta em ambos os cenários.

As verificações antigas de custo de meteoros foram atualizadas para RD e compromisso da próxima ação, conforme a nova regra. As fixtures de mouse headless definem explicitamente viewport 1200 × 700: o display headless nasce com janela 64 × 64 e projeção expandida quadrada, inadequada ao contrato do jogo. A mesma entrada também foi executada em display gráfico real 1200 × 700.

## Evidências do próprio Godot

| Captura | Conteúdo |
| --- | --- |
| [Piso antes](capturas/marco52_piso_antes.png) | Renderer do Marco 5 aprovado na mesma fixture |
| [Piso depois](capturas/marco52_piso_depois.png) | Fissuras e placas contínuas em 16 células adjacentes |
| [Piso aproximado](capturas/marco52_piso_aproximado.png) | Textura com zoom 2D em 1,8 |
| [Seleção contextual](capturas/marco52_selecao_contextual.png) | Xardorok e acólito na mesma região de clique |
| [Arena com zoom](capturas/marco52_arena_zoom.png) | HUD fixo, novos lacaios e remoção dos derrotados |
| [Reação Defensiva](capturas/marco52_reacao_defensiva.png) | Opções, consequências, estimativa de dano e recurso próprio |
| [Partida completa](capturas/marco52_partida_completa.png) | Derrota real observada ao final da partida |
| [Vitória com zoom](capturas/marco52_vitoria_zoom.png) | Faixa aprovada e projeção da coroa pela câmera |

As capturas não foram retocadas. O mecanismo de máscara/continuidade e a redução da repetição estão descritos em [TERRENO_MARCO52.md](TERRENO_MARCO52.md).

## Reproduzir

Abra `project.godot` no Godot 4.7.2 e pressione F5. Roda aproxima/afasta, Home restaura, botão do meio arrasta e F centraliza o selecionado. Tab abre/alterna alvos elegíveis, Enter confirma, Esc cancela. Durante meteoro, E seleciona evasão, D defende e Espaço não reage. R reinicia.

```sh
python tests/run_tests.py --godot /caminho/Godot
python tests/report_balance52.py
```

O primeiro comando importa, executa as suítes e as 36 partidas; o segundo só transforma o JSON já medido em relatório. Para reutilizar uma execução de balanceamento já concluída durante ajustes estritamente visuais, use `--skip-encounters` no primeiro comando. Para provas gráficas execute `tests/test_input_marco52.gd`, `tests/test_render_terrain_marco52.gd`, `tests/test_victory_marco52.gd` e `tests/test_match_visual_marco52.gd` com display real, sem `--headless`.

## Limitações

Windows, exportação executável e desempenho em GPU física não foram testados. O renderer gráfico foi exercitado por software em Linux. A fonte de textura é finita e pode revelar recorrências em áreas muito extensas. As 36 simulações (18 vitórias/18 derrotas) não substituem testes humanos de dificuldade; resultados e métricas estão em [BALANCEAMENTO_MARCO52.md](BALANCEAMENTO_MARCO52.md). A remoção lógica usa registros estáveis de mortos, deliberadamente sem remover entradas da lista de eventos durante uma animação.
