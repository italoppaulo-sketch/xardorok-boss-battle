# Piso vulcânico 2D — Marco 5.2

Base aprovada: `b437d480c37b3834aa944b15c4e95385d567832d` (Marco 5).
Nenhum código ou ativo do Marco 5.1 foi utilizado.

O fogo ambiental usa agora um campo visual contínuo: placas de rocha negra,
fissuras laranja e bordas queimadas irregulares, em vez de repetir a mesma chama
centralizada em cada célula. A imagem vulcânica fornecida pelo usuário foi
preservada sem edição em `assets/effects/marco52/volcanic_reference.png` e serve
como fonte de textura do shader CanvasItem. A arena e os personagens permanecem 2D.

## Continuidade, variação e segurança

- A amostragem usa coordenadas globais da arena. Uma célula adjacente não reinicia
  a imagem; fissuras e placas atravessam suas fronteiras internas.
- Uma pequena deformação de coordenadas, variação de luminosidade por posição e
  quatro amostras deslocadas ocultam as emendas da imagem sem criar simetria
  espelhada. Não há rotação ou decal idêntico por célula.
- O brilho varia lentamente em aproximadamente 6%, sem flashes que ocultem atores.
- Uma máscara de 2 pixels limita o desenho às células de `arena.visual_fire`.
  Bordas externas recuam de modo irregular dentro da região perigosa; a máscara
  nunca pinta uma célula segura. Bordas entre células incendiadas não têm recuo.
- A máscara só é reconstruída quando muda o conjunto de células. O shader utiliza
  quatro consultas de textura e ruído simples; nenhuma textura é gerada por frame.
- Este módulo não calcula dano, muda duração, ocupa células nem altera HP.
  `scripts/combat/fire_fields.gd` continua sendo a autoridade mecânica. O recuo
  artístico da borda não diminui a área lógica de dano da célula.
- Não existe borda entre uma célula isolada e uma vizinha apenas decorativa: só
  a lista de incêndios reais produz esta sobreposição animada.

## Evidência executada

Godot **4.7.2.stable.official.ed1daf0bf**, Linux, renderizador Compatibility,
OpenGL/Mesa llvmpipe, viewport gráfico real 1200 × 700.

| Captura | Conteúdo |
| --- | --- |
| [Antes](capturas/marco52_piso_antes.png) | Renderer original do Marco 5, 16 células adjacentes |
| [Depois](capturas/marco52_piso_depois.png) | Mesma fixture, posições e enquadramento; campo novo |
| [Aproximado](capturas/marco52_piso_aproximado.png) | Mesmo campo com câmera 2D em zoom 1,8 |

A captura anterior usa o script histórico aprovado, incorporado ao teste apenas
como fixture. Não substitui o renderer de produção durante o teste. As imagens
são pixels do viewport do Godot, sem composição ou pintura posterior.

Executados:

```sh
godot --headless --path . --script tests/test_terrain_marco52.gd
godot --path . --rendering-method gl_compatibility --script tests/test_render_terrain_marco52.gd
```

Resultado: **27 verificações de máscara, zero falhas; três capturas gráficas,
zero falhas**. Cobrem continuidade horizontal/vertical, ausência de textura em
células seguras, repetibilidade, limpeza, variação espacial e ausência de mutação
das zonas. Foram examinadas as três imagens para comparar a diferença perceptível.

Limite: há uma textura-fonte finita, portanto regiões muito extensas ainda podem
revelar elementos recorrentes. A mistura global reduz essa repetição; não equivale
a geração ilimitada de novas fotografias. Hardware Windows não foi validado aqui.
