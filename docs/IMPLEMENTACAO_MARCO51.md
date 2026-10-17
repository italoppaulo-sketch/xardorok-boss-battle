# Marco 5.1 — Implementação e migração controlada

## Base preservada

Base oficial: `feature/marco-5-polish`, commit `b437d480c37b3834aa944b15c4e95385d567832d`, correspondente ao Marco 5 aprovado pelo usuário, PR #4 ainda aberto. Desenvolvimento exclusivo em `feature/marco-5-1-camera-terrain`; nenhum merge ou alteração de branches históricas.

Antes das mudanças estruturais, uma cópia isolada do commit aprovado executou as 1.282 verificações e 36 partidas originais. Resultado: 29 vitórias e 7 derrotas; JSON de balanceamento byte a byte idêntico. A repetição foi necessária para estabelecer a base aprovada; a bateria final evita repetir simulações idênticas, pois os módulos de combate/IA/habilidades/dados não mudaram.

## Sequência de integração

1. Investigação independente da sobreposição: células lógicas exclusivas; o chefe capturava o clique destinado aos pés do lacaio adjacente. Caso reproduzido antes da correção e verificado depois.
2. Textura vulcânica baseada na imagem exata do usuário, renderer 2D e máscara contínua, testes e inspeção gráfica.
3. Cena experimental `scenes/experimental/camera_lab.tscn`, usando o controlador e motor aprovados. Prova de cliques reais para seleção, movimento e ataque em −90°, 0° e +90°, com três níveis de zoom.
4. Renderização gráfica e partida completa no laboratório, alternando câmera durante o combate. Somente depois dessas provas a apresentação foi habilitada em `scenes/main.tscn`.
5. Comparação preservada em `scenes/main_original.tscn`, argumento `--original-2d` e alternância F2 sem reiniciar a batalha.

## Componentes

| Componente | Responsabilidade |
| --- | --- |
| `tactical_orbit.gd` | Camera3D em órbita horizontal, zoom, foco, limites e suavização |
| `arena_stage3d.gd` | Piso e fundações, ruínas volumétricas, pedestais, luzes e colisões das quatro ruínas existentes |
| `hybrid_arena.gd` | Adaptador do Arena aprovado; conserva cronologia, snapshots, ocultação e mesmas unidades |
| `spatial_overlay.gd` | Projeta HP, nomes, seleção, alcance, áreas e destinos para a tela |
| `volcanic_surface.gd` | Máscara determinística compartilhada por materiais 2D/3D |
| `main.gd` | Um único Battle; seleciona a apresentação e mantém HUD fixo |

O mapeamento de células é `Vector3(cell.x - 7, 0, cell.y - 4)`. Uma célula corresponde a uma unidade espacial e mantém as distâncias Manhattan originais. O cenário usa Node3D, MeshInstance3D e Camera3D em modo Compatibility. Não é usada rotação de Camera2D.

## Sprites e profundidade

Os mesmos Actor2D/SpriteFrames renderizam em pequenos SubViewports transparentes; Sprite3D apresenta cada textura com billboarding e teste de profundidade. Assim são preservados quadros, temporização, buffs, duplicatas, chamas e animações. O material utiliza recorte alfa para evitar que a transparência de um sprite apague os demais. Sombras de chão são colocadas no plano espacial, sem duplicar a sombra plana vertical.

Nenhum personagem foi convertido para modelo tridimensional. PNGs e SpriteFrames de heróis, Xardorok, lacaios e Dalamud possuem guarda de hashes contra a base aprovada. Dalamud permanece um espírito, usando o mesmo shader etéreo e integração de buffs, sem unidade física adicional.

## Seleção e interface

A câmera transforma raios da posição atual do cursor em células do piso. Obstáculos usam camada física 1; piso usa camada 4. A seleção de unidades verifica pequenas bases projetadas primeiro e depois a transparência do quadro real, em ordem de profundidade. O corpo visível de uma unidade pode cobrir parte do chão atrás dela; escolha um ponto visível do destino ou use retratos para inspecionar personagens agrupados.

HUD e botões continuam no CanvasLayer aprovado e não giram ou mudam de escala com zoom. Os indicadores do mundo são projetados novamente a cada frame. A ocultação é decidida pelos snapshots da fumaça e pelo observador lógico, nunca pelo ângulo da câmera. Alterar o ângulo não revela alvos ocultos.

RMB/MMB/roda são encaminhados explicitamente pelo adaptador ao controlador orbital, pois o SubViewport do mundo não deve capturar cliques de combate. Soltar botões sobre o HUD também encerra o arrasto. Câmera não consome ações, bônus ou movimento.

## Efeitos

Aura, escudo, gelo e reação usam os mesmos atores e efeitos do Marco 5. Meteoros, raios, lasers, cura e números reutilizam eventos reais: seus pontos são reprojetados conforme a câmera se move. Os contornos das áreas são desenhados a partir das mesmas células lógicas. A fumaça recebe volumes visuais e conserva ocultação real. Fogo do piso usa uma única superfície espacial mascarada; sua animação não chama regras de dano. A coroa da vitória também é reprojetada na trajetória espacial.

## Limitações conhecidas

- Billboarding preserva uma perspectiva corporal única; não mostra costas ou lados novos. Esse limite existe mesmo em uma órbita de 180°.
- Arquitetura nova é uma representação modular simplificada usando texturas existentes. O fundo distante de tempestade permanece uma imagem decorativa, não um céu volumétrico completo.
- Partículas e traços de magia são efeitos 2D reprojetados, enquanto arena, corpos de profundidade e seleção são espaciais. Não são simulações físicas de projéteis 3D.
- Zoom próximo pode cortar partes da arena; F centra o selecionado e Home restaura o enquadramento. Os limites evitam atravessar o piso.
- A referência vulcânica fornecida tem resolução limitada; aproximações extremas não adicionam detalhes inexistentes.
- Sobreposição projetiva natural de sprites adjacentes pode ocorrer. Profundidade, bases selecionáveis e retratos garantem acesso sem mover ou ocultar artificialmente as unidades.
- Testado em Linux/Godot 4.7.2/Mesa llvmpipe; Windows, outros drivers e exportação executável precisam de validação no computador do usuário.
