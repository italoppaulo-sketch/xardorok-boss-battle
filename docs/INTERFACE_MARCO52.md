# Interface e câmera — Marco 5.2

A câmera continua integralmente 2D. `scripts/visuals/tactical_zoom.gd` estende `Camera2D`, sem rotação nem conversão da arena. A posição das unidades e as regras da grade permanecem no modelo de combate; a interface usa `CanvasLayer` e fica fixa.

## Controles

| Comando | Resultado |
| --- | --- |
| Roda do mouse sobre a arena | Aproxima/afasta suavemente, entre 0,85 e 1,8; parâmetros exportados |
| Home | Restaura imediatamente zoom 1 e centro original |
| Arrastar com botão do meio | Desloca a câmera dentro dos limites de observação |
| F | Centraliza no personagem selecionado e identificado |
| Clique em combatentes próximos | Abre lista contextual quando há vários candidatos elegíveis |
| Tab / Shift+Tab | Abre lista ou percorre alvos elegíveis nos dois sentidos |
| Enter | Confirma o candidato destacado |
| Esc | Cancela a lista; na escolha do destino de evasão, volta às respostas |
| E / D / Espaço na resposta a meteoros | Evadir / Defender / Não reagir |
| R | Reinicia a batalha e o enquadramento |

O zoom usa filtragem `nearest`, preservando os sprites existentes. O clique é convertido pelo inverso da transformação de canvas, de modo que células e personagens continuam correspondendo ao cursor depois de zoom e deslocamento. O arraste termina mesmo quando o botão do meio é solto sobre a interface.

## Seleção contextual

`target_selector.gd` apresenta nome, retrato, aliado/inimigo e HP dos candidatos. A seleção segue o modo atual: ao escolher uma habilidade dirigida, somente alvos aprovados por `battle.can_use` entram na lista. A cura oferece aliados; ataques oferecem inimigos válidos. No modo de movimento é possível selecionar heróis ou inspecionar inimigos.

Unidades mortas ou não identificáveis pela fumaça ficam fora da lista. A validade é conferida outra vez na confirmação. A troca de modo, início da animação de combate, troca de herói, reinício, resposta ao meteoro ou fim de batalha fecha a lista e limpa o destaque. A lista é uma interface transitória em coordenadas de tela; não move combatentes nem modifica a ocupação da grade.

## Reação Defensiva e meteoros

A interface mostra Reação, Ação e Bônus separadamente. A janela só aparece quando `battle.meteor_window` está ativa. As três respostas indicam o momento do impacto e suas consequências:

- **EVADIR:** uma Reação Defensiva, destino seguro de até duas células, sacrifício de exatamente uma ação principal. O botão informa dinamicamente “ação atual” ou “próxima ação”; o custo não se acumula nos dois momentos.
- **DEFENDER:** uma Reação Defensiva, sem exigir bônus ou PM, redução de 50% do dano do meteoro, preservando a próxima ação principal. Efeitos secundários continuam possíveis.
- **NÃO REAGIR:** conserva os recursos e aceita o dano integral se permanecer na região atingida.

Botões indisponíveis são desabilitados e seus motivos ficam no tooltip. Os valores aproximados de dano são calculados sobre as marcas reais de `battle.meteors`, incluindo resistência a fogo, defesa temporária, buff de ataque de Xardorok e o arredondamento da redução de defesa emergencial. Várias áreas sobrepostas são somadas; incêndios posteriores não entram nessa estimativa. A reação não concede um turno adicional e não repõe ações ou mana.

## Verificações de desenvolvimento

Executados em Godot **4.7.2.stable.official.ed1daf0bf**, reutilizando o executável existente:

- Importação e inicialização headless sem erros após as correções.
- `gdlint` nos quatro arquivos de interface/câmera sem problemas.
- Probe dirigido: **17 verificações passaram**, cobrindo câmera 2D, parentesco da câmera, limites, restauração imediata, HUD fixo, abertura/ciclo/destaque/cancelamento da lista, alvo aliado de cura, opção de defesa, estimativa baseada no meteoro real e reinício.

As capturas e a regressão integrada são registradas no relatório geral de validação do Marco 5.2. O probe é apenas uma verificação de desenvolvimento; não substitui os testes gráficos e de combate integrados.
