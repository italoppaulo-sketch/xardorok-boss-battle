# Xardorok Boss Battle

Fundação de um RPG tático 2D no Godot 4.
**Dalamud é um espírito aliado dos heróis.** Sua intervenção será implementada em um marco posterior.

## Abrir esta versão no Windows

1. Extraia o ZIP em uma **pasta separada** para experimentar sem substituir seu projeto atual.
2. No gerenciador de projetos do Godot, clique em **Importar** e selecione o `project.godot` da pasta extraída.
3. Aguarde a importação e pressione **F5**. A cena inicial é `scenes/main.tscn`.

A publicação automática no GitHub foi impedida por erro 403 de permissão da integração. **Não existe branch remota ou pull request desta entrega.** A branch local de desenvolvimento é `codex/marco-1-fundacao`; a `main` remota permanece intacta.

### Incorporar pelo GitHub Desktop

Após experimentar o pacote, abra seu repositório original no GitHub Desktop, salve eventuais alterações locais e use **Branch → New branch** para criar `codex/marco-1-fundacao`. Copie para a pasta do repositório as pastas `scenes`, `scripts`, `tests`, `docs`, o `README.md` e o `project.godot` deste pacote. Se houver trabalho local novo nesses caminhos, compare antes de substituir. Não apague nem substitua a pasta `.git`. Revise as alterações no Desktop, faça o commit e clique em **Publish branch**. Depois, reabra o projeto original no Godot e pressione F5.

## Jogar

- Selecione um herói pelos botões, teclas **1–5** ou clicando nele na arena.
- Escolha **Mover** e clique em um destino. Os pontos azuis indicam destinos alcançáveis; a grade interna fica oculta.
- Escolha **Ataque básico** e clique em Xardorok. Ataques exigem alcance e linha de visão.
- Cada herói recebe **5 passos e 1 ataque** por rodada. Você pode alternar entre heróis e distribuir as ações.
- **Espaço** ou **Encerrar rodada dos heróis** executa a ação do chefe e renova os recursos do grupo.
- **R** ou **Reiniciar batalha** começa outra partida.
- Para vencer, reduza o HP de Xardorok a zero. A queda de todos os heróis encerra a partida em derrota.

## Organização

| Arquivo | Responsabilidade |
| --- | --- |
| `scenes/main.tscn` | Cena inicial |
| `scripts/main.gd` | Liga entrada, modelo e interface |
| `scripts/combat/battle.gd` | Movimento, ocupação, visão, ataques, IA e resultado |
| `scripts/data/roster.gd` | Elenco e parâmetros provisórios |
| `scripts/world/arena.gd` | Arena e desenhos provisórios |
| `scripts/ui/battle_hud.gd` | Seleção, ações e estado da partida |
| `tests/test_battle.gd` | Testes executáveis no motor |

## Validação no Godot

No terminal, substitua `godot` pelo caminho do executável, se necessário:

```text
godot --headless --path . --editor --quit
godot --headless --path . --script tests/test_battle.gd
godot --headless --path . --script tests/test_scene.gd
godot --headless --path . --quit-after 120
```

Os testes verificam movimento, obstáculos, ocupação, alcance, visão, economia de ações, IA, vitória e derrota. O teste automatizado não substitui conferir os controles e a apresentação visual no editor. Consulte [docs/VALIDACAO.md](docs/VALIDACAO.md) para o que foi efetivamente executado.

## Limites desta entrega

Este é o Marco 1, com formas geométricas provisórias e ataques básicos. Os poderes especiais, ações bônus, efeitos temporários, resistências, lacaios, Dalamud, cinematografia, arte definitiva, áudio, vídeo e exportação Windows ainda não estão implementados. Os números são de balanceamento inicial. A IA usa perseguição simples ao herói mais próximo; não é ainda o comportamento definitivo do chefe.

Próximo passo: Marco 2, começando por recursos de habilidade e estados alterados, com testes individuais.
