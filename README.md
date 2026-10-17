# Xardorok Boss Battle — Marco 4: O Trono das Cinzas

RPG tático em **Godot 4.7.2**, continuando os Marcos 1–3. Esta versão traz iniciativa individual, reações anunciadas, duas fases de Xardorok, fumaça com ocultação real, arena de ruínas e tempestade e HUD com retratos e ícones. Os sprites aprovados dos cinco heróis e de Dalamud foram preservados.

## Abrir no Windows

1. No GitHub Desktop, use **Fetch origin** e escolha **feature/marco-4-boss-hud**. Use Pull se houver atualização.
2. Abra `project.godot` no Godot 4.7.2, aguarde a importação e pressione **F5**.
3. Se usar o pacote ZIP, extraia tudo em uma pasta separada e importe seu `project.godot`.

O PR desta versão parte de `feature/marco-3-visual`; os PRs anteriores ainda aguardavam revisão na entrega. Não há merge automático na `main`.

## Jogar

- A faixa superior mostra a ordem, o combatente ativo e o próximo. Cada combatente tem seu próprio turno: **5 passos, 1 ação e 1 bônus** para cada herói. Só o ativo pode agir.
- Iniciativa fixa: Kodokami 18, Thomas 16, Thuxil 15, Grosso 14, Xardorok 13, Cassandra 12. Acólitos têm 17, desempate pela ordem de invocação, e só entram na rodada seguinte ao nascimento.
- **1–5** ou retratos: inspecionar Grosso, Kodokami, Cassandra, Thomas e Thuxil. Inspecionar outro herói não transfere o turno.
- **Esc / Mover:** clique nos pontos previstos do piso para se deslocar. Na fumaça, ocupantes não vistos podem tornar um trajeto previsto inviável. Não há obstáculos invisíveis fixos.
- **A:** ataque básico. **Q / W / E / T:** habilidades da barra. Clique no alvo/chão indicado. Habilidades pessoais são executadas ao escolher seu ícone.
- **Espaço:** encerrar o turno individual. Os inimigos agem automaticamente quando chega a vez deles. **R:** reiniciar, inclusive durante animações.
- Passe o mouse sobre ícones para nome completo, descrição, custo, tipo de ação, alcance, recarga e impedimentos. O registro de combate abre/fecha pelo botão inferior direito.

Comandos ficam bloqueados durante a apresentação de uma ação. O modelo resolve o efeito uma única vez; animações e barras da arena acompanham os eventos de impacto. HP/PM no painel reconciliam ao término da sequência.

## Habilidades preservadas

| Personagem | Habilidades |
| --- | --- |
| Grosso | Pele Glacial, Martelo Glacial, Ataque Duplo, Forma Gigante |
| Kodokami | Ataque Desarmado Duplo, Esquiva Elevada, Fushigiri com custo de 24 HP |
| Cassandra | Antimagia, Cura, Raio de Fogo Roxo |
| Thomas | Flecha Enraizante, Flecha de Gelo em área, Flecha Energizada, Botas Mágicas |
| Thuxil | Duplicata Ilusória, Raio Azul Encadeado, Silêncio |
| Xardorok | Ataque físico, fumaça, meteoros, invocação e aura passiva; duas fases e reações |
| Acólitos | Laser vermelho arcano; alternativa física sob silêncio |

Custos e efeitos vêm do catálogo `scripts/data/abilities.gd`. Antispell foi renomeada na interface para **Antimagia**, mantendo o identificador estável `antispell`.

## Regras novas e interações

- **Duração:** estados expiram no fim do turno do portador, incluindo o turno atual para buffs pessoais. Recargas diminuem e 8 PM regeneram no início do próximo turno do portador. Ações inválidas não gastam recursos.
- **Chefe:** 900 HP; transição única a 450 HP. Fase 2 intensifica apresentação/aura e escolhas de pressão, sem restaurar HP, apagar estados ou conceder outro turno.
- **Armadura:** Xardorok reduz dano final recebido em 28%, além de resistir a físico 30%, sombra/raio 20%, violeta 15%, fogo 45%. Gelo mantém vulnerabilidade de 25%. Pele Glacial reduz dano recebido, mas não neutraliza a aura.
- **Reações:** após cada dois turnos de heróis encerrados, até duas por rodada. São preparações de brasa ou comando contextual dos acólitos; não consomem a ação regular. Silêncio e congelamento impedem sua preparação mágica. Uma brasa anuncia uma célula para a rodada seguinte: mova-se ou use Antimagia.
- **Meteoros:** marcam áreas Manhattan de raio 1, que só impactam quando Xardorok age na rodada seguinte. Marcas das reações usam raio 0. Há oportunidade de ação para todos os heróis antes do impacto; silêncio/congelamento não apagam uma preparação anterior.
- **Fumaça:** raio 3, duração de duas rodadas. A visão corresponde ao herói ativo ou ao último herói ativo vivo durante os turnos inimigos. Quem está na mesma região pode se perceber; de fora, sprites, nomes, HP, seleção, retratos e informações de alvo ficam ocultos. Não há visão coletiva atravessando a nuvem.
- **Área e memória:** Flecha de Gelo pode mirar o chão sem visão direta e atingir ocultos sem revelá-los. Ataques direcionados e saltos elétricos exigem visão. A IA procura posições vistas anteriormente quando perde o alvo; não acompanha posições ocultas atuais.
- **Antimagia:** dissipa fumaça e marcas, remove debuffs de aliados ou buffs de inimigos conforme o catálogo; não ressuscita, não remove a armadura/aura passivas e não revela alvos que continuem sem linha de visão.
- **Voo/Gigante:** voo cruza ruínas/unidades e exige pouso livre; não é invulnerabilidade. Gigante muda escala, força e alcance, mantendo uma célula lógica e colisões. O chefe e o gigante têm base de seleção ligada aos pés.
- **Fim:** derrotar Xardorok vence mesmo com acólitos vivos. A queda dos cinco heróis causa derrota. Reinício remove iniciativa anterior, regiões, estados, efeitos, reações e invocações.

**Dalamud é um espírito ancestral aliado.** Sua manifestação e buffs permanecem no ponto de integração `scripts/support/spirit_support.gd`, sem unidade física ou regra nova de invocação pelo jogador. A cinematografia final continua fora do escopo.

## Organização

| Módulo | Função |
| --- | --- |
| `scripts/combat/battle.gd` | Estado, validações, turno individual, dano e resultado |
| `scripts/combat/initiative.gd` | Ordem explícita e entrada de lacaios |
| `scripts/combat/reactions.gd` | Reações limitadas, sem cadeia recursiva de turnos |
| `scripts/combat/perception.gd` | Visão compartilhada entre regras, IA e apresentação |
| `scripts/combat/arena_geometry.gd` | Recorte da plataforma e ruínas bloqueantes |
| `scripts/data/boss_config.gd` | HP, dano, armadura, resistências, pesos, recargas, fases e limites |
| `scripts/ai/` | Escolhas contextuais e busca de última posição vista |
| `scripts/visuals/` | Sprites, cronologia, fumaça, efeitos e cenário |
| `scripts/ui/battle_hud.gd`, `scenes/ui/` | Iniciativa, retratos, habilidades e registro |
| `assets/ui/ability_icons/` | Ícones originais e manifesto de associação |

A plataforma tem 119 células visuais, quatro ruínas físicas periféricas e 115 células transitáveis. As antigas colunas centrais foram removidas também das regras. Ruínas exteriores, tochas com pedestal e gelo nas fissuras não criam bloqueios sem representação.

## Testar e revisar

```text
python tests/run_tests.py --godot CAMINHO_DO_GODOT
python tests/report_balance.py
```

Com display, sem `--headless`:

```text
godot --path . --script tests/test_render.gd
godot --path . --script tests/test_render_marco4.gd
godot --path . --script tests/test_showcase.gd
```

[Validação e capturas reais](docs/VALIDACAO_MARCO4.md) · [Balanceamento](docs/BALANCEAMENTO_MARCO4.md) · [Arte e prompts](docs/ARTE_MARCO4.md) · [Demonstração curta](docs/demos/marco4_demo.mp4).

Testes executados no Godot 4.7.2 Linux/OpenGL por software. Windows, exportação executável, GPU física e áudio não foram testados/entregues. Os novos recursos artísticos aguardam revisão. As 27 simulações venceram em 5–7 rodadas; a dificuldade permanece permissiva nesse lote e precisa de partidas humanas, conforme o relatório. Os relatórios dos marcos anteriores ficam preservados como histórico, não como descrição do sistema atual.
