# Xardorok Boss Battle — Marco 2

RPG tático 2D em Godot **4.7.2**, ampliando o protótipo do Marco 1. Combate jogável com os cinco heróis, habilidades especiais, estados temporários e IA contextual de Xardorok. Os desenhos de personagens ainda são estudos provisórios; sprites e cinematografia definitivos ficam para etapas posteriores.

## Atualizar e jogar no Windows

1. No GitHub Desktop, abra este repositório e clique em **Fetch origin**.
2. Em **Current branch**, selecione **feature/marco-2**. Use **Pull origin** se houver atualizações.
3. Abra o projeto no Godot 4.7.2, aguarde a importação e pressione **F5**.

Salve eventuais alterações locais antes de trocar de branch. A `main` mantém o Marco 1 até que o pull request seja revisado e incorporado. Não é necessário copiar ZIPs.

## Controles

- **1–5** ou os botões superiores: selecionar Grosso, Kodokami, Cassandra, Thomas e Thuxil.
- **Mover**: clique nos pontos azuis para andar. A grade tática permanece oculta.
- **Ataque básico** ou uma habilidade: clique no alvo indicado; Cura aceita aliado vivo e Antispell também aceita chão.
- Habilidades pessoais são executadas ao clicar no botão. Usam a **ação bônus**, deixando a principal disponível.
- Cada herói tem **5 passos, 1 ação principal e 1 bônus** por rodada. Pode alternar livremente entre os heróis.
- **Espaço**: encerrar a fase do grupo. Ordem consistente: **heróis → Xardorok → lacaios**, por ordem de invocação.
- **Esc**: voltar a mover. **R**: reiniciar completamente a batalha.
- Passe o mouse sobre unidades para consultar HP/estados e sobre habilidades para ler descrição e impedimentos.

A interface apresenta HP, PM, movimento, ação, bônus, alcance, recargas e estados. Marcas vermelhas mostram exatamente as células de impacto dos meteoros; indicadores de habilidade mostram alvos válidos, área de gelo e saltos do raio.

## Habilidades

| Herói | Habilidades implementadas |
| --- | --- |
| Grosso | Pele Glacial, Martelo Glacial, Ataque Duplo, Forma Gigante |
| Kodokami | Ataque Desarmado Duplo, Esquiva Elevada, Fushigiri com custo de HP |
| Cassandra | Antispell, Cura, Raio de Fogo Roxo |
| Thomas | Flecha Enraizante, Flecha de Gelo em área, Flecha Energizada, Botas Mágicas |
| Thuxil | Duplicata Ilusória com bônus, Raio Azul Encadeado, Silêncio |
| Xardorok | Aura incandescente, ataque físico, Bolha de Fumaça, Chuva de Meteoros, invocação de guerreiros de cinzas |

Custos, alcance, dano e recargas são configuráveis em `scripts/data/abilities.gd`. Números de balanceamento são iniciais. Não há compras nem dependências de serviços pagos.

## Regras de interação

- **PM:** 100 iniciais; recupera 8 por rodada, até o máximo. Habilidades inválidas não gastam recursos. Ataque básico não custa PM.
- **Duração:** estados contam turnos do portador e são atualizados ao finalizar sua fase. Buffs pessoais incluem a fase de ativação. Estados iguais renovam a duração, sem acumular multiplicadores.
- **Recarga:** diminui ao iniciar a próxima fase do personagem. Uma recarga de 2 usada na rodada 1 libera na rodada 3.
- **Crítico/esquiva:** crítico natural de 10%, multiplicador 1,5; esquiva física natural de 5%, 25% para Kodokami. Esquiva Elevada soma 30 pontos percentuais. Magias elementais não usam esquiva física.
- **Duplicata:** a próxima habilidade de dano garante crítico e consome a ilusão; não ocupa célula nem cria outro combatente. Dura no máximo 2 turnos.
- **Gelo e fogo:** Xardorok resiste a 45% do fogo comum e recebe 25% a mais de gelo. O fogo violeta de Cassandra é arcano e distinto do fogo comum.
- **Aura:** ao finalizar a fase dos heróis, inimigos a 1 passo de Xardorok recebem 10 de fogo, sujeitos à defesa, com 35% de chance de queimadura. Continua ativa sob silêncio/congelamento. Queimadura causa 8 de fogo por turno.
- **Pele Glacial:** defesa reduz dano em 35%; espinhos devolvem 8 de gelo em golpes de contato. O dano da aura continua perigoso.
- **Martelo:** adiciona 12 de gelo por golpe e 35% de chance de congelar por 1 turno. Combina com ataque duplo e forma gigante.
- **Gigante:** tamanho visual animado de 1,6, força +35% e alcance físico +1; mantém a mesma célula lógica e todas as colisões.
- **Voo:** +2 passos e travessia sobre pilares/unidades, mas o destino precisa ser chão livre. Não concede invulnerabilidade; ao expirar, o personagem já está sobre chão válido.
- **Fumaça:** bloqueia visão entre dentro/fora e ao atravessar a região. Unidades dentro da mesma bolha ainda se enxergam. Antispell ignora linha de visão para dissipá-la.
- **Antispell:** remove fumaça, marcas de meteoro, estados negativos de aliados ou buffs de inimigos. Não ressuscita nem apaga a aura passiva.
- **Meteoros:** marcam áreas de raio Manhattan 1 e só impactam na próxima fase inimiga; há uma fase inteira dos heróis para escapar. Silêncio não desfaz magias já preparadas; Antispell pode cancelá-las.
- **Lacaios:** até 3 vivos, com HP e recursos próprios. Agem a partir da rodada seguinte à invocação. Ataques em área não causam fogo amigo.
- **Fim:** derrotar Xardorok vence a batalha mesmo com lacaios restantes. Todos os heróis caídos causam derrota. Reiniciar limpa tudo, incluindo efeitos visuais.

**Dalamud é um espírito ancestral aliado.** O ponto de integração `scripts/support/spirit_support.gd` concede buffs pelo mesmo sistema de estados, sem criar um corpo físico. Sua aparição e cinematografia não fazem parte deste marco.

## Arquitetura

O Marco 1 permanece como base: mesma cena inicial, coordenadas, elenco, controles e APIs básicas de combate. Novas responsabilidades foram separadas:

| Módulo | Responsabilidade |
| --- | --- |
| `scripts/combat/battle.gd` | Estado da partida, validação, dano e fases |
| `scripts/combat/navigation.gd` | Caminhos, ocupação, voo e perseguição |
| `scripts/combat/statuses.gd` | Catálogo, duração, remoção e descrição dos estados |
| `scripts/data/abilities.gd` | Dados configuráveis das habilidades |
| `scripts/abilities/executor.gd` | Execução mecânica das habilidades |
| `scripts/ai/xardorok_ai.gd` | Pontuação de opções conforme distância, alvos, HP e disponibilidade |
| `scripts/world/arena.gd` | Cenário, seleção, indicadores e interpolação do movimento |
| `scripts/world/unit_painter.gd` | Silhuetas provisórias e estados visuais |
| `scripts/world/effects.gd` | Projéteis, cortes, raios, partículas e números flutuantes |
| `scripts/ui/battle_hud.gd` | Interface e descrições |

## Testar

Com Python 3 e o executável do Godot disponível:

```text
python tests/run_tests.py --godot "caminho/para/Godot_v4.7.2-stable_win64.exe"
```

Ou execute as suítes individualmente:

```text
godot --headless --path . --editor --quit
godot --headless --path . --script tests/test_battle.gd
godot --headless --path . --script tests/test_abilities.gd
godot --headless --path . --script tests/test_scene.gd
godot --headless --path . --script tests/test_input.gd
godot --headless --path . --script tests/test_encounters.gd
godot --headless --path . --quit-after 120
```

O teste gráfico requer display e deve ser executado **sem** `--headless`:

```text
godot --path . --script tests/test_render.gd
```

Resultados e limitações em [docs/VALIDACAO.md](docs/VALIDACAO.md). Ainda não há áudio, sprites aprovados, exportação Windows ou vídeo cinematográfico final.
