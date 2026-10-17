# Xardorok Boss Battle — Marco 5: A Ira do Rei das Cinzas

RPG tático em **Godot 4.7.2 / GDScript**, continuando o Marco 4. Corrige o desaparecimento indevido perto das ruínas e acrescenta escudo, aura ativável, meteoros com resposta limitada, incêndios, IA contextual e vitória cinematográfica. Os sprites aprovados dos cinco heróis e de Dalamud permanecem preservados.

## Executar no computador

1. No GitHub Desktop, use **Fetch origin**, escolha **feature/marco-5-polish** e atualize a branch.
2. Abra `project.godot` no **Godot 4.7.2**, aguarde a importação e pressione **F5**.
3. Se usar o ZIP, extraia o pacote inteiro em uma pasta separada e importe `project.godot`. Não copie apenas os scripts.

O PR parte de `feature/marco-4-boss-hud`, pois o Marco 4 ainda aguarda revisão. Nenhuma alteração é incorporada automaticamente à `main`. Não há plugins ou dependências de execução externos.

## Jogar

- A faixa superior mostra a iniciativa individual. Cada herói recebe **5 passos, 1 ação principal e 1 bônus** no próprio turno.
- **1–5** ou retratos: inspecionar Grosso, Kodokami, Cassandra, Thomas e Thuxil. Só o combatente ativo pode agir.
- **Esc / Mover:** clique nos pontos do piso. Movimento comum gasta passos, preservando a ação principal.
- **A:** ataque básico. **Q / W / E / T:** habilidades da barra; clique no alvo ou no chão. Habilidades pessoais executam ao selecionar o ícone.
- **Espaço:** encerrar turno; os inimigos agem automaticamente. Durante resposta de meteoro, confirma **manter posição**.
- Durante o aviso de meteoro, **E** seleciona evasão e depois um destino marcado; **D** usa defesa. **Esc** volta às opções sem fechar a janela.
- **R:** reiniciar inclusive durante animações, resposta de meteoro e vitória. **Espaço** pula a sequência de vitória depois que ela começar.
- Passe o mouse sobre ícones para descrição, custo, alcance, estados e recargas. O botão inferior direito abre o registro de combate.

A iniciativa fixa começa com Kodokami 18, Thomas 16, Thuxil 15, Grosso 14, Xardorok 13 e Cassandra 12. Acólitos têm 17 e entram na rodada seguinte à invocação. Inspecionar outro herói não transfere o turno.

## Combate e regras do Marco 5

| Recurso | Regra |
| --- | --- |
| Abertura do chefe | Primeira ação principal válida invoca até 2 magos. Silêncio, congelamento, falta de espaço/recursos ou limite podem impedir; a IA tenta novamente. |
| IA posterior | Pontua distâncias, concentração, HP, pressão recebida, lacaios, fases, visão e recargas. Não segue ciclo fixo. |
| Escudo de Fogo | Ação principal; 2 fins de turno do portador, incluindo ativação. Reduz dano em 40% além da armadura; devolve 6 fogo somente em contato que cause dano. Não acumula. |
| Recarga do escudo | Começa em 3 ao terminar ou ser dissipado; diminui nos inícios dos próximos turnos próprios. Não pode ser reativado enquanto ativo ou em recarga. |
| Aura de Fogo | Começa desligada. Ativação custa bônus; dura 3 fins de turno próprios. Herói adjacente recebe 16 fogo (20 na fase 2) ao encerrar seu turno, uma vez por evento, com 35% de queimadura. |
| Antimagia | Dissipa fumaça e buffs mágicos compatíveis, inclusive escudo e aura. Não remove a armadura intrínseca. |
| Silêncio | Impede novas conjurações/reação mágica; ataques físicos continuam. Aura já ativada e escudo já lançado permanecem até expirar/dissipar. |
| Meteoros | Marcam até 2 áreas Manhattan de raio 1. A iniciativa pausa para uma resposta de cada herói ameaçado; o impacto vem após a última, sem rodadas extras. Reações usam raio 0 e menor dano. |
| Evasão emergencial | Exige ação disponível e destino livre fora de todas as marcas em até 2 passos. Gasta a ação. Fora do turno ativo, reserva também a próxima ação principal: esse turno começa com 0 ações; o seguinte volta a 1. Congelamento/enraizamento impedem. |
| Defesa de meteoro | Custa 1 bônus + 8 PM atuais; reduz somente o dano dos impactos desta janela em 50%. Congelamento impede. Não renova recursos. |
| Permanecer | Não custa recursos; recebe o dano caso continue na área. |
| Incêndio | Impacto anuncia e incendeia células válidas por 2 rodadas. Entrar ou encerrar turno nelas causa 8 fogo, no máximo uma vez por combatente/turno lógico. Voo evita travessia intermediária, mas não o pouso no fogo. Não bloqueia movimento. |
| Navegação inimiga | Considera risco de incêndio e busca caminhos alternativos. Acólitos procuram sair do fogo quando podem. |
| Fases e reações | 900 HP; fase 2 a 450 HP, sem cura ou turno adicional. Até 2 reações por rodada, após cada 2 turnos de heróis. Brasa usa a mesma janela curta; comando fortalece magos. |

Estados expiram ao fim do turno do portador, incluindo o atual para buffs pessoais; recargas diminuem e 8 PM regeneram no início do turno próprio. Custos inválidos não são debitados. Ações normais ficam bloqueadas na janela de resposta e durante animações.

Se Xardorok morrer, as marcas pendentes se dissipam e a vitória não fica bloqueada. Mudança de fase mantém marcas e seus valores já anunciados. Resolver uma janela novamente não reaplica impactos. O movimento comum preserva as regras aprovadas.

## Habilidades preservadas

| Personagem | Habilidades |
| --- | --- |
| Grosso | Pele Glacial, Martelo Glacial, Ataque Duplo, Forma Gigante |
| Kodokami | Ataque Desarmado Duplo, Esquiva Elevada, Fushigiri com custo de 24 HP |
| Cassandra | Antimagia, Cura, Raio de Fogo Roxo |
| Thomas | Flecha Enraizante, Flecha de Gelo em área, Flecha Energizada, Botas Mágicas |
| Thuxil | Duplicata Ilusória, Raio Azul Encadeado, Silêncio |
| Xardorok | Ataque físico, fumaça, meteoros, invocação, Escudo de Fogo e Aura de Fogo |
| Acólitos | Laser vermelho arcano e alternativa física sob silêncio |

Armadura intrínseca do rei: multiplicador de dano 0,72, resistências físico 30%, sombra/raio 20%, violeta 15%, fogo 45%, vulnerabilidade a gelo 25%. Pele Glacial ajuda Grosso, mas não o imuniza contra fogo. Voo e forma gigante mantêm pouso/ocupação válidos e não conferem invulnerabilidade.

**Dalamud é um espírito ancestral aliado.** A integração para futuros buffs permanece em `scripts/support/spirit_support.gd`; não é um dragão físico nem um sexto combatente permanente. Não foi produzida a cinematografia final de Dalamud.

## Visibilidade e apresentação

A fumaça mantém ocultação real de corpo, nome, HP, retrato e inspeção para quem está fora da região; personagens na mesma nuvem podem se perceber. Ataques e IA mantêm LOS das ruínas. A apresentação dos sprites usa separadamente a ocultação de fumaça, evitando que uma ruína baixa apague o ator inteiro.

A arena tem 119 células visuais, quatro obstáculos periféricos e 115 células transitáveis. Braseiros ocupam esses suportes; ruínas externas não alteram a navegação. O gelo decorativo foi retirado; gelo temporário das habilidades permanece. Fogo ativo do piso tem chamas animadas, distintas das texturas queimadas decorativas.

A vitória começa após o impacto final, com queda desacelerada visualmente, coroa desprendida e faixa dourada original. Dura 3,6 segundos e pode ser pulada. Não altera o relógio lógico do combate.

## Arquitetura e validação

- `scripts/combat/battle.gd`: estado, recursos, dano, turnos e resultado.
- `scripts/combat/meteor_resolution.gd`: subfase de resposta; `fire_fields.gd`: incêndios e deduplicação.
- `scripts/combat/navigation.gd`: BFS de movimento e busca de menor risco para IA.
- `scripts/ai/`, `scripts/data/boss_config.gd`: decisões e parâmetros configuráveis.
- `scripts/world/arena.gd`, `scripts/visuals/`: apresentação sequenciada por eventos reais.
- `scripts/ui/battle_hud.gd`: iniciativa, recursos, ícones e respostas.

```text
python tests/run_tests.py --godot CAMINHO_DO_GODOT
python tests/report_balance.py
```

Testes gráficos requerem display, sem `--headless`:

```text
godot --path . --rendering-method gl_compatibility --script tests/test_render_marco5.gd
godot --path . --rendering-method gl_compatibility --script tests/test_match_visual_marco5.gd
```

Consulte [validação](docs/VALIDACAO_MARCO5.md), [balanceamento](docs/BALANCEAMENTO_MARCO5.md), [diagnóstico do bug](docs/BUG_VISIBILIDADE_MARCO5.md), [arte e licença](docs/ARTE_MARCO5.md) e [capturas reais](docs/capturas/).

Validação realizada em Linux com Godot 4.7.2 oficial. Windows, exportação executável e dificuldade definitiva para jogadores humanos continuam sujeitos a teste no computador do usuário. Os três seeds por política não equivalem a uma pesquisa com jogadores. Trilha e efeitos sonoros permanecem para a próxima etapa.
