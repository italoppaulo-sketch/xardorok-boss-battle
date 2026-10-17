# Arte integrada — Marco 3

A geração utilizou a ferramenta nativa de imagens, em modo de edição com as referências originais anexadas para os personagens. Os retratos do usuário não são distribuídos no repositório. Para lacaios, efeitos e cenário foi usada geração textual. Não foram usados serviços externos pagos.

## Especificação dos prompts

Padrão comum: pixel art de RPG 2D, três quartos frontal, iluminação coerente, fundo transparente, nenhum texto/grade pintada, células separadas, poses reais articuladas, identidade consistente. Uma folha por personagem com 8 colunas e 4 linhas; oito quadros de repouso/caminhada, oito de dois ataques distintos, quatro de conjuração, dois de reação, dois de esquiva, quatro de queda e quatro especiais. Dalamud usa folha de 4 × 2 poses aladas.

| Folha | Instruções de identidade e movimento |
| --- | --- |
| Grosso | Referência do grupo: calvo, tatuagens azuis, barba ruiva trançada, torso grande exposto, peles/correias e martelo quadrado. Caminhada pesada; marteladas superiores/laterais; conjuração glacial e força gigante. Sem armadura de gelo permanente. |
| Kodokami | Referência do grupo: cabelos pretos desalinhados, cachecol preto sobre o rosto, trajes marciais escuros e katana. Socos distintos, evasão e desembainhar/corte sombrio da Fushigiri. |
| Cassandra | Referência do grupo: cabelos pretos ondulados, capuz/vestido azul com detalhes discretos e vestido claro interno. Conjuração com as mãos, cura e fogo violeta; sem cajado ou chapéu inventado. |
| Thomas | Referência do grupo: cabelo preto espetado, couro/metal escuro, correias e ombreira/joelhos dourados. Arco discreto exigido pela função; puxar/soltar flecha e flutuação das botas. |
| Thuxil | Retrato individual: cabeça bronze/cobre dracônica, espinhos para trás, gola de pele clara, cachecol/couro castanho e fecho circular. Mãos elétricas, duplicata e gestos de silêncio. Continuação neutra das pernas não vistas. |
| Xardorok | Retrato da primeira forma, preservando velho rei, barba branca longa, coroa escura e espada angular. Alteração autorizada: segunda forma de armadura negra incandescente, sem capa/casaco. Ataques físicos, conjuração e queda. |
| Acólito | Novo design autorizado: mago de capuz/robe escuro, rosto oculto, vermelho discreto. Mãos carregam energia; dispara laser vermelho. Sem equipamento de guerreiro. |
| Dalamud | Referência do dragão vermelho/chifres claros, agora espírito aliado flutuante: asas e bênção em oito poses, pernas recolhidas, sem solo. Shader aplica translucidez e luz etérea no jogo. |

Prompts auxiliares: nove linhas de quatro fases de efeitos (gelo, fogo violeta, eletricidade azul, flechas douradas, ilusão/silêncio, cura, fumaça, meteoros e laser vermelho); folha modular de oito pisos quadrados e 24 props individuais; fundo distante de castelo, montanhas e lua **sem piso/plataforma ilustrada**.

Foram corrigidas duas folhas nas quais armas invadiam células vizinhas e substituídos estudos de Dalamud com excesso de fumaça. Somente atlas finais limpos são carregados pelo jogo. Os resultados são estudos v1 integrados, sem alegar aprovação artística definitiva.

## Empacotamento técnico

- Personagens: `assets/characters/<id>/atlas.png`, metadados `atlas.json` e recurso editável `animations.tres` de SpriteFrames. Quadros de 112 × 128; pés em `(56,118)`. Sete folhas de 32 poses e uma de oito: 232 quadros corporais.
- Efeitos: `assets/effects/<família>/atlas.png`, quatro quadros de 96 × 96 por família. Corpos e efeitos têm alfa real.
- Arena: oito texturas de piso, 24 props e fundo distante. Quatro variantes de piso, pilares, quatro quadros de braseiro, cristais, trono e correntes estão integrados; os demais props ficam disponíveis para composições futuras.
- Filtro nearest, sem mipmaps. Escala global constante dentro de cada atlas, sem redimensionar cada pose independentemente. Região transparente conserva a âncora; formato do golpe muda dentro da célula.
- Cenas reutilizáveis em `scenes/characters`, `scenes/effects` e `scenes/environments`; recursos podem ser editados individualmente sem trocar regras de combate.

As folhas raster foram geradas pela ferramenta de imagens; os utilitários Python apenas detectam alfa, recortam células, alinham e redimensionam por nearest. Eles não desenham arte criativa. Dependências opcionais da ferramenta offline: Pillow, NumPy e SciPy. O jogo requer somente Godot.

```text
python tools/pack_sprite_atlas.py folha.png assets/characters/personagem --height 64
python tools/pack_sprite_atlas.py espirito.png assets/characters/dalamud --height 78 --columns 4 --rows 2
python tools/pack_world_assets.py --effects efeitos.png --environment modulos.png --background fundo.png
```

As folhas de geração não são necessárias para abrir o projeto: todos os PNGs finais e os SpriteFrames já estão versionados. Para regenerar, forneça novas folhas seguindo a disposição acima, usando as referências autorizadas; o script rejeita células vazias ou componentes incompatíveis. Não basta reutilizar uma pose estática para substituir animações.
