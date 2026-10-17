# Arte e apresentação — Marco 5

Os atlas e SpriteFrames dos cinco heróis, de Dalamud e dos lacaios foram preservados. Os novos efeitos são camadas independentes; não calculam dano, recursos, duração de estados ou alvos.

## Recursos novos

`assets/effects/marco5/` contém seis atlas PNG RGBA de 384 × 96, quatro quadros de 96 × 96 por família:

| Arquivo | Uso |
| --- | --- |
| aura.png | Chamas baixas irregulares ao redor do chefe, somente com `fire_aura` ativo. |
| shield.png | Casulo vertical de chamas, distinto da aura, somente com `fire_shield` ativo. |
| hit_fire.png | Chamas sobre a vítima e brasas ao receber dano lógico identificado como aura, escudo, meteoro ou incêndio. |
| floor_fire.png | Incêndios temporários de células e chamas decorativas em suportes/ruínas. |
| floors.png | Quatro variações opacas: pedra queimada, rachaduras incandescentes e marca de explosão. |
| electric.png | Concentração nas mãos, impacto elétrico, faíscas e dissipação do raio azul. |

Os ícones `assets/ui/ability_icons/fire_aura.png` e `fire_shield.png` reutilizam o primeiro quadro dos efeitos correspondentes, reduzido para 64 × 64. O manifesto registra a origem. Os 35 ícones anteriores permanecem inalterados; o catálogo agora contém 37 ícones distintos, todos com transparência. Nenhuma geração adicional foi necessária.

Os PNGs de efeitos possuem transparência real e margens vazias. A exportação técnica verificou 56%–74% de pixels transparentes; os pisos são inteiramente opacos. Recortes e redução usam nearest-neighbor. A ferramenta `tools/pack_marco5_effects.py` não desenha arte: apenas separa o atlas de origem, normaliza a escala e preserva o alpha. Python, NumPy e Pillow são ferramentas de exportação, não dependências do jogo.

Foi utilizada uma única geração nativa de imagem, em modo built-in, com fundo transparente. Não houve chamada a API paga externa. Prompt de produção utilizado, resumido sem alterar o conteúdo artístico:

> Atlas de pixel art JRPG de 16 bits, 4 colunas × 6 linhas, 24 células quadradas isoladas e sem texto. Linha 1: quatro poses de coroa baixa de fogo laranja/vermelho, centro vazio, perspectiva elíptica irregular. Linha 2: quatro poses de escudo oval vertical de fogo, laterais e arco de chamas, centro vazio. Linha 3: quatro explosões de chamas e brasas envolvendo a metade inferior de um humanoide ausente. Linha 4: quatro poses de incêndio no piso com carvão. Linha 5: quatro pisos de pedra queimada, fuligem, rachaduras laranja, cascalho e marca de explosão. Linha 6: concentração elétrica azul/branca, impacto ramificado, faíscas e fragmentos. Margens transparentes de 12%, sem personagens, gelo decorativo, interface ou legendas.

## Integração

- `fire_envelope.gd`: sobreposição animada de aura e escudo no ator. Os estados controlam sua presença; morte encerra ambos.
- `fire_fields.gd`: desenha exclusivamente as células de `arena.visual_fire`, copiadas do combate. Não inventa regiões perigosas e não aplica dano.
- `effects_renderer.gd`: raio com carga nas mãos, núcleo luminoso irregular, ramificações e impactos PNG. Os eventos `link` reais definem quais pares são conectados. A arena agenda os saltos e o dano correspondente em ordem; o efeito não escolhe novos alvos. `electric_pulse()` ilumina brevemente o sprite atingido.
- `arena_environment.gd`: nenhuma fissura/cristal de gelo decorativo é instanciado. Os quatro braseiros com pedestais ocupam exatamente `Geometry.WALLS`. Não acrescentam obstáculos invisíveis. Ruínas externas recebem fogo animado, luz quente e brasas; o piso mantém a geometria oficial, com variações queimadas.
- `victory_sequence.gd`: CanvasLayer modular, 3,6 segundos, sem alterar `Engine.time_scale`. Usa a coroa PNG já existente, queda/rebote, escurecimento, faixa translúcida e texto próprio dourado **REI DAS CINZAS DERROTADO**. O relógio de animação do chefe desacelera brevemente; o combate não é recalculado. `skip()` avança para o quadro final; `reset()` remove a apresentação. O main oferece Espaço para avançar e R para reiniciar.

A tipografia de vitória utiliza DejaVu Serif distribuída com sua licença em `assets/ui/fonts/DejaVu-LICENSE.txt`. A imagem de referência serviu apenas para composição, hierarquia e atmosfera. Nenhum recurso gráfico ou texto de Elden Ring foi copiado.

## Limites e revisão

A arte de fogo é uma primeira versão integrada ao jogo, sujeita à avaliação visual do usuário. As partículas procedurais são somente pequenos pontos/segmentos luminosos em torno dos atlas PNG, sem substituir sprites de personagens. O brilho permanece moderado para preservar HP, alvos e HUD. O atlas de origem não é necessário para executar ou editar os recursos exportados.
