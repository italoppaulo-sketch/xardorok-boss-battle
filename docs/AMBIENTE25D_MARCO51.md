# Ambiente 2.5D — Marco 5.1

A cena experimental usa `scripts/camera/arena_stage3d.gd`. `setup()` é idempotente e não cria câmera, atores ou regras de combate. Cada célula lógica corresponde a um metro: `(x - 7, 0, y - 4)`.

O palco reutiliza exclusivamente PNGs existentes. Há 119 planos de piso, com variação determinística entre três texturas aprovadas, e fundações com volume. Os quatro obstáculos de `Geometry.WALLS` recebem suportes físicos e braseiros. Não foram adicionados obstáculos em células navegáveis.

Os arcos externos combinam volumes de pedra e relevos dos PNGs originais; assim, mantêm espessura quando vistos lateralmente. Torres partidas compõem o horizonte. Iluminação ambiente fria e luzes locais de fogo funcionam no renderizador Compatibility. As chamas reutilizam o atlas de quatro quadros e animam sem gerar números aleatórios por quadro.

A colisão física da camada 1 contém somente os quatro obstáculos lógicos. A camada 4 contém um plano de seleção retangular; quem faz a seleção deve validar `Geometry.valid_cell()` para rejeitar os cantos vazios do recorte oval. A navegação continua sob responsabilidade do motor de combate.

O palco não trata a superfície vulcânica, os atores, a câmera ou o HUD: esses módulos são integrados separadamente. Não foram alterados sprites aprovados nem geradas imagens novas.

## Validação executada

Com Godot `4.7.2.stable.official.ed1daf0bf`, o comando `--headless --path . --script tests/test_stage51.gd` passou em **251 verificações**, sem falhas. O teste cobre inicialização idempotente, transformação de coordenadas, os quatro suportes e suas camadas, seleção física de todas as 119 células e ausência de colisores de obstáculo nas outras 115 células. Isso valida estrutura e física; a composição visual deve ser examinada na cena experimental integrada e nos ângulos da câmera.
