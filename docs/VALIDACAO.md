# Marco 2 — implementação e validação

Data: 17/10/2026. Base oficial: `main`, commit `6ab02bd3595ec8e9495fd9b7793e802248d26b98` (Marco 1 publicado pelo usuário). Desenvolvimento em `feature/marco-2`, para revisão por pull request; sem merge automático.

## Ambiente efetivamente utilizado

**Godot 4.7.2 stable oficial, Linux x86_64, build `ed1daf0bf`**. O motor foi obtido da distribuição oficial. A configuração do projeto, a cena inicial e os arquivos previamente aprovados foram mantidos. Não houve acesso ao editor Windows do usuário.

A auditoria da árvore publicada não encontrou cache `.godot`, credenciais ou temporários versionados. A branch parte da `main`, sem reconstruir o projeto. O `.gitignore` foi reforçado para exportações, logs e configurações privadas.

## Resultado das suítes executadas

| Verificação | Resultado |
| --- | --- |
| Importação e compilação: `--headless --editor --quit` | Concluídas, sem erros reportados |
| `tests/test_battle.gd` | 22 verificações passaram; regressão das regras básicas do Marco 1 |
| `tests/test_abilities.gd` | 119 verificações passaram; todas as habilidades e estados |
| `tests/test_scene.gd` | 46 verificações passaram; menus, execução, animação de tamanho, resultados e reinício |
| `tests/test_input.gd` | 18 verificações passaram; eventos de mouse/teclado enviados ao viewport e limites dos controles |
| `tests/test_encounters.gd` | 20 partidas completas desde as posições originais, sementes diferentes: 20 vitórias, nenhuma falha de integridade |
| Cena principal por 120 frames em modo sem janela | Sem erros reportados |
| `tests/test_render.gd` com display X11 virtual e OpenGL real | 22 cenários renderizados, nenhuma falha |
| `gdparse`, `gdlint`, `gdformat --check`, `git diff --check` | Aprovados |

São **205 verificações explícitas** nas quatro primeiras suítes, além das partidas e dos cenários gráficos. As partidas também verificam limites de HP/PM, recursos não negativos, ocupação, ausência de unidades em pilares e limite de lacaios a cada etapa. O comportamento aleatório usa sementes reproduzíveis; os testes de valores exatos desativam as rolagens.

O executor `tests/run_tests.py` falha tanto por código de saída quanto por mensagens de erro do Godot, pois erros de script nem sempre produzem saída diferente de zero.

## Matriz dos casos obrigatórios

| Caso | Evidência executada |
| --- | --- |
| Grosso recebe dano da armadura de fogo | Teste com Pele Glacial e chefe silenciado; HP diminui |
| Gigante aumenta sem atravessar obstáculos | Alcance e buff conferidos; pilar rejeitado; tamanho interpolado verificado na cena |
| Fushigiri cobra HP | Custo exato de 24 HP/20 PM; tentativa com HP insuficiente rejeitada sem gasto |
| Flecha Enraizante imobiliza | Estado aplicado e deslocamento do alvo rejeitado |
| Voo e retorno ao solo | Caminho curto sobre pilar, pouso sobre pilar rejeitado, dano físico recebido e expiração |
| Cura funciona | Aliado curado sem exceder máximo; caído não é ressuscitado |
| Cassandra dissipa fumaça | Visão bloqueada antes e restaurada após Antispell; teste de dentro/fora |
| Duplicata usa bônus | Ação principal preservada; nenhuma unidade física extra |
| Raio atinge vários inimigos | Três alvos/conexões; crítico da ilusão elimina dois lacaios |
| Chefe silenciado permanece físico | Eventos da fase contêm ataque físico e nenhuma conjuração |
| Meteoros respeitam áreas | Sem dano imediato; fuga evita dano; permanência causa 40; marcas removidas |
| Lacaios agem | Não agem ao nascer; movem/atacam na rodada seguinte; máximo de três |
| Estados expiram | Todos os 12 estados testados por duas fases; queimadura causa dano antes de terminar |
| Vitória e derrota | Testes do modelo e das mensagens na interface; vitória também em partidas completas |
| Reinício sem resíduos | HP, PM, estados, recargas, lacaios, fumaça, meteoros, rotas e efeitos visuais limpos |

Também foram testados: dano de contato refletido, vulnerabilidade a gelo, combinação martelo/ataque duplo, custo de ações, recargas, esquiva com RNG reproduzível, habilidades de outras classes rejeitadas, alvo inválido, mana insuficiente, remoção de debuffs/buffs e cancelamento de marcas com Antispell.

## Conferência gráfica

Renderização real pelo GL Compatibility, usando **Mesa llvmpipe** em display X11 virtual de 1200 × 700. Foram inspecionadas capturas internas do início da batalha, seleção de Cassandra e Forma Gigante. Não se trata apenas da execução com renderizador dummy em modo sem janela.

Os cenários automatizados cobrem as 17 habilidades especiais dos heróis, as três magias do chefe e dois ataques básicos. O teste confere a obtenção de frames com largura de 1200 pixels. O driver virtual informou que não oferece controle de V-Sync; isso não impediu renderização ou testes.

A leitura dos nomes nos botões e o espaço para estados foram ajustados após a inspeção. Estados extensos têm duas linhas visíveis e descrição completa no tooltip, evitando cobrir os controles. Silhuetas, cenário e efeitos continuam provisórios e não substituem sprites a serem aprovados.

## Correções encontradas durante os testes

- Entrada da arena passou a usar a coordenada do evento de mouse, transformada para o canvas. O teste pelo viewport encontrou a diferença que os testes por sinais diretos não detectavam.
- A seleção de aliados para Cura/Antispell preserva o conjurador, em vez de trocar de personagem antes de usar a habilidade.
- A invocação respeita o limite mesmo quando solicitada repetidamente.
- Tipos explícitos foram adicionados onde a inferência do GDScript não era suficiente.
- As fixtures gráficas foram corrigidas para colocar o ataque desarmado em alcance corpo a corpo.

## Limitações conhecidas

- **Windows:** execução nativa e driver gráfico do computador do usuário ainda precisam de conferência local. A versão exata 4.7.2 foi executada em Linux.
- **Arte:** desenhos e animações são estudos em código, sem os sprites finais baseados nas referências aprovadas. Não há áudio neste marco.
- **Balanceamento:** custos, chances, resistências e pontuação da IA são iniciais. As 20 vitórias automatizadas demonstram uma estratégia possível; não provam equilíbrio de dificuldade para jogadores.
- **Tempo das animações:** a resolução das regras é imediata e os eventos são animados em seguida. Não há ainda direção cinematográfica com câmera e bloqueio de controles por sequência.
- **Dalamud:** arquitetura de buffs pronta e testada; manifestação espiritual e cinematografia permanecem para a próxima etapa.
- **Entrega:** projeto para abrir no editor; não foi feita exportação Windows nem produzido vídeo final.

## Executar localmente

No GitHub Desktop: **Fetch origin → Current branch → feature/marco-2 → Pull origin** quando necessário. No Godot 4.7.2: abrir o projeto e pressionar **F5**. O README contém controles, regras, módulos e comandos de teste.
