# Terreno vulcânico — Marco 5.1

A referência fornecida pelo usuário foi copiada sem alterações para `assets/effects/marco51/volcanic_reference.png` (506 × 193). Não houve geração de imagens nem substituição por textura genérica. O material usa suas rochas vitrificadas negras e fissuras alaranjadas. O arquivo é um recurso fornecido pelo usuário; sua inclusão não constitui verificação independente de licença para distribuição comercial.

## Implementação

`VolcanicSurface` é um recurso exclusivamente visual. A fotografia é amostrada em coordenadas globais contínuas da arena, com frequência de 2,7 × 2,1 e espelhamento nas extremidades: não existe um quadrado de textura reiniciado em cada célula. Uma deformação suave e estável, derivada da semente, evita regularidade de linhas; as fissuras ficam suficientemente pequenas para serem reconhecidas mesmo em dois ou três quadrados adjacentes. A máscara é calculada nas coordenadas contínuas do piso, com 32 amostras por célula. Células vizinhas compartilham a superfície sem linha de separação. Ruído FastNoiseLite de semente fixa 5107 varia a largura das bordas, sempre para dentro das células perigosas. As transições são suaves dentro dessa faixa; uma célula segura conserva máscara zero. Uma pulsação discreta varia somente o brilho da lava. A apresentação 2D recebe brasas esparsas com fases diferentes por região.

A fonte de verdade continua sendo `battle.fire_zones`, recebida através do snapshot da arena. Células fora do tabuleiro e obstáculos são descartados. O renderer não chama dano, não altera HP, não cria estados nem modifica duração. A máscara é reconstruída somente quando o conjunto de células muda; a textura GPU mantém a identidade durante atualização e extinção. Não há cálculo de máscara em cada quadro.

## API compartilhada 2D e 2.5D

```gdscript
var surface = preload("res://scripts/visuals/volcanic_surface.gd").new(Vector2i(15, 9), 5107)
surface.update_zones(battle.fire_zones, battle.WALLS)
var material_3d = surface.spatial_material()
# PlaneMesh: tamanho igual à arena inteira, UV de 0 a 1, ligeiramente acima do piso.
# A mesma instância deve ser mantida entre snapshots.
```

`canvas_material()` e `spatial_material()` compartilham a mesma fotografia e máscara. Ambos usam UV globais da arena; a versão espacial não constitui outro motor de combate. `update_zones` retorna `true` somente quando há mudança; a ordem de entrada das células não altera o resultado. Outro valor de semente modifica as bordas orgânicas de forma reproduzível.

## Validação executada

- Godot **4.7.2.stable.official.ed1daf0bf**, importação real dos recursos: sem erro de importação.
- `tests/test_terrain_marco51.gd`: **20 verificações, zero falhas**. Inclui referência correta, ausência inicial, ativação, continuidade dos dois lados de uma borda compartilhada, célula segura sem lava, centro perigoso identificado, suavização interna, determinismo, variação por semente, cache, extinção, vínculo dos dois materiais, descarte de paredes e posições inválidas, preservação dos dados de combate e integração na arena 2D.
- Execução gráfica real da arena 2D, OpenGL Compatibility / Mesa llvmpipe, viewport 1200 × 700: shader compilado e fotografia renderizada, sem erro de shader. Captura inspecionada durante a implementação.

## Limitações conhecidas

A fotografia é uma referência estática de resolução 506 × 193; a animação atua no brilho, sem criar movimento físico de lava. A amostragem global espelhada preserva sua continuidade, mas aproximações extremas evidenciam essa resolução. As bordas continuam correspondendo às células das regras: a suavização não estende lava a células seguras. O recorte lógico pode ser reconhecido em um incêndio isolado; inventar perigo fora das regras para esconder esse recorte prejudicaria a leitura tática.
