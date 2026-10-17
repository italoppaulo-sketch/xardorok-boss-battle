# Validação — Marco 4

## Ambiente e execução

Testes executados no Linux x86_64 com **Godot 4.7.2 stable official, commit ed1daf0bf**. O projeto foi importado pelo editor headless e iniciou por 120 quadros sem erros de script. O modo headless valida regras e integração de cena, não qualidade visual da renderização.

Comando executado:

```bash
python tests/run_tests.py --godot /tmp/godot472/Godot_v4.7.2-stable_linux.x86_64
```

A execução final registrada pelo runner da entrega terminou com código 0, sem `ERROR:`. O runner considera erro de script como falha mesmo quando o processo Godot retorna 0.

## Resultados funcionais

| Suíte | Verificações | Resultado |
|---|---:|---|
| `test_battle.gd` | 23 | Passou |
| `test_marco4.gd` | 413 | Passou |
| `test_abilities.gd` | 119 | Passou |
| `test_scene.gd` | 46 | Passou |
| `test_input.gd` | 28 | Passou |
| `test_visuals.gd` | 496 | Passou |
| **Total de verificações explícitas** | **1.125** | **0 falhas** |
| `test_encounters.gd` | 27 partidas + invariantes por operação | 0 falhas de integridade |
| Importação pelo editor | Projeto completo | Passou |
| Inicialização | 120 quadros | Passou |

`gdlint scripts tests`, `gdformat --check scripts tests` e `git diff --check` passaram. Os testes de integração aguardam os eventos de apresentação: o modelo aplica o dano uma vez, a barra muda no instante do impacto e comandos ficam bloqueados durante a animação.

### Cobertura preservada e ampliada

- Habilidades reais de todos os heróis: dano e resistências, bônus, custo de HP da Fushigiri, gelo, contato, tamanho, voo, cura, dissipação, ilusão, crítico, cadeia, silêncio e esquiva.
- Iniciativa explícita `[1,3,4,0,5,2]`; Kodokami inicia. Bloqueio de principal, bônus e movimento fora do turno; principal e bônus independentes; derrotados ignorados; lacaios entram na rodada seguinte.
- Durações no fim do turno do portador e recargas/recursos no início. Outros combatentes não adiantam a expiração. Queimadura causa dano antes de desaparecer.
- Chefe com 900 HP, resistências e armadura configuráveis. Danos esperados são explícitos: ataque básico de Grosso causa 16, Fushigiri 72 e Flecha de Gelo 34 ao chefe nesta configuração. A transição em 450 HP ocorre uma vez, preservando estados e recursos.
- Reações após dois turnos de heróis, máximo de duas por rodada, renovação na rodada seguinte, aviso sem dano imediato, ação principal preservada e bloqueio por congelamento/silêncio. Invocar `act_enemy()` duas vezes no mesmo turno não duplica aura nem eventos.
- Fumaça de raio 3: chefe, herói e acólito ocultos para observador exterior; percepção compartilhada dentro da mesma região; entrada/saída; ataque direcionado bloqueado; área causa dano sem revelar; Antimagia e expiração natural removem a região.
- Ocultação na cena/HUD: sprite, nomes/HP via mesma guarda do overlay, retrato, informações do alvo e barra do chefe. A prévia de movimento não denuncia a célula ocupada por um oculto; o movimento real mantém colisão.
- Plataforma oval com 119 células, 115 navegáveis após quatro ruínas periféricas; centro sem colunas invisíveis; navegação não sai do piso e unidades vivas não se sobrepõem.
- 35 ícones distintos, 64×64, com alfa, catálogo associado e recursos importados. Sprites aprovados dos heróis preservados; animações do novo Xardorok verificadas. Ilusão e Dalamud continuam sem criar combatente físico permanente.
- Cliques reais no viewport e atalhos: inspecionar herói, bloquear habilidade fora do turno, Esquiva, mover, encerrar turno, voo, reinício, registro recolhível e botões dentro de 1200×700.
- Vitória, derrota e reinício: limpam estados, recargas, lacaios, zonas mágicas, rotas, efeitos, agenda e espírito.

As fixtures de habilidades isoladas posicionam o personagem e o tornam ativo para testar cada mecânica sem interferência de outros turnos. A suíte de iniciativa e as 27 partidas não fazem essa alteração: usam a sequência real e provam os bloqueios.

## Balanceamento

O relatório [BALANCEAMENTO_MARCO4.md](BALANCEAMENTO_MARCO4.md) e o [JSON completo](balanceamento_marco4.json) registram nove estratégias × sementes 17, 42 e 99. Nenhuma vitória foi fabricada ou exigida como condição de aprovação. O ensaio final com armadura de redução de 28% terminou com 27 vitórias, 0 derrotas, entre 5 e 7 rodadas; a fase 2 ocorreu nas 27 partidas.

**A dificuldade continua permissiva neste lote.** O grupo de mau posicionamento também venceu. O lote registrou 6 ataques físicos, 25 Chuvas de Meteoros, 18 fumaças, 3 invocações e 181 reações. O dano nominal do chefe somou 3.675 e o dos lacaios, 91. Todas as famílias de ações do chefe apareceram; as marcas de reação são contabilizadas separadamente. A iniciativa 17 dos acólitos permite que atuem antes de Thomas e Thuxil na rodada seguinte à invocação. A ausência de derrotas permanece como limitação observada, não como prova de balanceamento definitivo. Fumaça, meteoros e turnos/ataques dos lacaios passaram em testes funcionais isolados.

## Renderização e capturas

Executados com renderização real **GL Compatibility/OpenGL 4.5, Mesa llvmpipe**, em display X11 virtual 1200 × 700. O framebuffer foi lido do motor real, sem usar o renderizador dummy do modo headless.

| Execução gráfica | Resultado |
| --- | --- |
| `tests/test_render.gd` | 22 cenários de habilidades, nenhuma falha |
| `tests/test_render_marco4.gd` | 8 cenários específicos do Marco 4, nenhuma falha |
| `tests/test_showcase.gd` | Partida completa desde posições/HP/recursos originais: vitória na rodada 5, nenhuma falha |

Os oito cenários verificam arena/HUD, ocultação de chefe/herói/lacaio, entrada na nuvem, Antimagia, transição única com barra/legenda sincronizadas, reação intermediária, marcas de meteoros e registro recolhível. São fixtures controladas; não se confundem com as 27 partidas de balanceamento ou a partida completa apresentada. A partida gráfica usa tempo de apresentação acelerado em quatro vezes, preservando regras, HP, recursos e iniciativa.

Capturas reais: [arena e HUD](capturas/marco4_hud_arena.png), [fumaça por fora](capturas/marco4_fumaca_oculta.png), [visão dentro da nuvem](capturas/marco4_fumaca_interior.png), [Antimagia](capturas/marco4_antimagia.png), [segunda fase](capturas/marco4_fase2.png), [reação](capturas/marco4_reacao.png), [meteoros](capturas/marco4_meteoros.png), [registro](capturas/marco4_registro.png) e [fim da partida completa](capturas/marco4_vitoria.png). Também há capturas de Fushigiri, laser e Dalamud em `docs/capturas`.

A [demonstração MP4](demos/marco4_demo.mp4) tem 6,4 segundos, sem áudio, e foi montada a partir de 64 frames reais dos cenários de teste, reproduzidos a 10 quadros por segundo. É uma demonstração técnica curta, com cenários controlados e transições por reinício; não é vídeo cinematográfico nem registro contínuo de uma partida inteira. O único aviso gráfico foi V-Sync indisponível no driver por software; não houve erro de script ou shader nas execuções finais.

A inspeção visual conferiu legibilidade de nome/HP/PM, ícones, ausência das colunas centrais, apoio dos braseiros, frio nas fissuras, origem de sprites e ocultação completa. Clicar nos pixels do corpo/coroa de Xardorok mapeia para a célula lógica de seus pés, sem ampliar colisões. A memória indicada ao passar o mouse por uma posição antiga não rastreia movimentos ocultos nem revela HP atual.

## Limitações

- Não foram executados testes no Windows, exportação executável ou ensaio de desempenho em equipamento do usuário.
- Três sementes por política não constituem validação estatística de dificuldade. São necessárias partidas humanas e novas sementes para calibrar pressão do chefe e prioridade contextual das habilidades.
- A plataforma usa um recorte oval em células, com bordas em degraus; não há navegação contínua circular nem câmera em perspectiva 3D.
- O registro de combate e a memória exibem somente informações permitidas pela percepção do jogador; alvos ocultos não exibem dados atuais.
- A aprovação funcional não equivale à aprovação artística dos novos recursos. A direção visual deve ser revisada pelo usuário nas capturas reais.

## Integridade da entrega

Base: Marco 3, commit `eb2334533da65c95fdfb229bd19587e180cba083`. Branch `feature/marco-4-boss-hud`, com três commits organizados de arte, motor e integração/validação; sem merge automático. Os arquivos PNG e SpriteFrames dos cinco heróis e de Dalamud não tiveram alterações. O trabalho gráfico desta etapa usou quatro gerações nativas: folha de Xardorok, folha de ícones, folha modular e fundo distante. Os retratos do HUD são recortes técnicos dos sprites aprovados. Nenhum retrato original do usuário, executável do Godot, cache `.godot` ou pacote de dependência está no projeto versionado.
