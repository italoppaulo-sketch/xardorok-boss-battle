# Marco 1 — auditoria e validação

Data: 17/10/2026. Base: `main`, commit `1c4be71f91f3874c686d4323e730f6a93dd5c57b`.

## Auditoria

O conector GitHub confirmou acesso de leitura e escrita. A branch principal continha o commit inicial e seis arquivos: configurações do editor/Git, ícone, importação do ícone e `project.godot`. Não havia cenas, scripts, recursos aprovados de personagem ou instruções AGENTS.md. Todos os arquivos originais foram preservados; apenas `project.godot` recebeu cena inicial, dimensões da janela e cor de fundo.

O projeto declara `4.7` em `config/features`, renderização GL Compatibility e física 3D Jolt. O novo protótipo é 2D e não depende da física 3D. A versão exata do editor instalado no computador do usuário não pôde ser conferida remotamente.

O ambiente inicialmente não tinha Godot. Após uma primeira falha de rede, foi possível baixar a distribuição oficial Linux **Godot 4.5.1 stable** para testes. Não houve acesso ao editor Windows do usuário. A configuração original de versão foi mantida.

## Verificações executadas

- `gdparse`: todos os scripts e testes com sintaxe válida.
- `gdlint`: sem problemas.
- `gdformat --check`: formatação consistente.
- `git diff --check`: sem erros de whitespace.
- Godot 4.5.1, `--headless --editor --quit`: importação e carregamento concluídos sem erros reportados.
- Godot 4.5.1, `--headless --script tests/test_battle.gd`: **22 verificações passaram**, nenhuma falha. Cobrem regras de combate e perseguição do grupo pela IA até a derrota.
- Godot 4.5.1, `--headless --script tests/test_scene.gd`: **13 verificações passaram**, nenhuma falha. Cobrem instanciação da cena, seleção por botões, modos, sinal de clique da arena, rodada e reinício.
- Godot 4.5.1, `--headless --quit-after 120`: cena principal executada por 120 frames sem erros reportados.

## Limitações e conferência no Windows

Não foi realizada inspeção visual em janela, interação física de mouse/teclado, execução no Godot 4.7.2 nem exportação para Windows. Os testes da interface emitem sinais dos controles e da arena programaticamente. Confirmar localmente leitura dos textos, clique em coordenadas da arena, atalhos, redimensionamento e apresentação final da vitória/derrota.

## Entrega

`project.godot` é a única modificação de arquivo original. Foram adicionadas uma cena, cinco scripts de produção, dois scripts de teste, README e documento de validação. Os `.uid` são identificadores gerados pelo Godot para esses scripts.

Os recursos visuais são provisórios. Não foi gerada arte nem consumido serviço externo pago. O README registra Dalamud como espírito, cuja implementação está prevista para marco posterior.

## Publicação

A integração GitHub retornou HTTP 403 (`Resource not accessible by integration`) ao tentar criar a árvore de arquivos e a branch. Nenhum commit, branch remota ou pull request desta entrega foi publicado. O projeto é entregue em ZIP, sem histórico `.git`, para teste local e incorporação pelo GitHub Desktop.

A revisão automática também impediu a inclusão do prompt integral no repositório público. Esse documento foi retirado da entrega pública proposta; somente código e documentação operacional foram preparados para publicação.
