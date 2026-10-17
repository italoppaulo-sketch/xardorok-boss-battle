# Arte do Marco 4

## Recursos produzidos

Foram usadas duas gerações nativas de imagem: uma folha de 35 ícones e uma folha de 32 poses de Xardorok. Não houve uso de API externa ou geração de novas versões dos heróis. Os PNGs, SpriteFrames e manifestos finais ficam no projeto; as fotos originais do usuário não são publicadas.

`assets/ui/ability_icons/` contém PNGs RGBA independentes de 64×64, atlas 448×320 e `manifest.json`, com associação estável entre identificador, arquivo e região. A ilustração é reduzida por vizinho mais próximo, com margem transparente, para leitura em barras de habilidades. A interface deve aplicar os estados de indisponibilidade/recarga sem criar novos arquivos ou alterar a arte-base.

Legenda por linha, da esquerda para a direita:

| Linha | Coluna 1 | Coluna 2 | Coluna 3 | Coluna 4 | Coluna 5 | Coluna 6 | Coluna 7 |
|---|---|---|---|---|---|---|---|
| 1 | skin | hammer | double | giant | unarmed | dodge | fushigiri |
| 2 | root_arrow | ice_arrow | energy_arrow | flight | antispell | heal | purple_fire |
| 3 | illusion | chain | silence | smoke | meteors | summon | red_laser |
| 4 | basic_0 | basic_1 | basic_2 | basic_3 | basic_4 | basic_5 | basic_6 |
| 5 | move | end_turn | aura | reaction | phase | spirit | frozen |

`basic_0..6` representam, respectivamente: Grosso, Kodokami, Cassandra, Thomas, Thuxil, Xardorok e lacaio. O nome real da habilidade continua sendo `basic`; os sufixos selecionam sua representação conforme o combatente. Aura/reaction/phase são identificadores de apresentação de mecânicas do chefe, e spirit/frozen são indicadores de apoio/estado. Estes últimos não autorizam criar habilidades selecionáveis inexistentes no catálogo.

`assets/characters/xardorok_marco4/` preserva as versões anteriores e fornece atlas 896×512, 32 quadros em células 112×128, âncora constante (56,118), e `animations.tres`. A altura mediana de repouso é 82 px, antes da escala moderada aplicada pelo jogo. O corpo mais ereto, a coroa negra legível, o tórax largo e as fissuras de fogo ampliam a presença visual sem alterar a célula lógica ocupada. A sombra e os efeitos adicionais continuam sob responsabilidade do runtime.

Animações: idle 0–3; walk 4–7; attack 8–11; attack_alt 12–15; cast 16–19; hit 20–21; evade 22–23; death 24–27; special 28–31. Repouso e caminhada repetem; as demais encerram. As poses incluem articulação de membros, torso e arma, com progressão própria de conjuração e transição de fase.

## Referências e limites

A imagem original de Xardorok foi examinada juntamente com o atlas do Marco 3. Foram preservados rosto envelhecido, barba branca longa, coroa de ferro escuro e espada angular. A armadura negra incandescente sem capa corresponde à transformação já autorizada; a foto mostra a forma anterior, com casaco de pele, e não uma referência direta da armadura nova. Os sprites dos cinco heróis e Dalamud não foram redesenhados.

Os ícones são originais, orientados pelo catálogo real e pela paleta de cada classe. Referências de organização de HUD não foram usadas como recursos copiados. A associação `antispell` continua válida mesmo quando a interface apresenta o nome Antimagia.

O estilo ainda está sujeito à revisão artística do usuário. Comparação por hashes confirma quadros distintos, mas não substitui a avaliação de fluidez no jogo. A leitura dos ícones em 48 px e a escala do chefe devem ser avaliadas nas capturas reais da versão integrada.

## Reprodução técnica

Os prompts finais e o modo utilizado estão em `tools/art_prompts_marco4.json`. Os utilitários `tools/pack_ability_icons.py` e `tools/pack_sprite_atlas.py` fazem apenas recorte, preservação de alfa, dimensionamento e empacotamento; não desenham os personagens nem substituem geração de arte. A dependência Pillow, e NumPy/SciPy no empacotador de personagens, é exclusiva do processo offline. O jogo não precisa dessas bibliotecas.

Os testes de recursos verificam 35 ícones distintos com transparência real, 32 quadros distintos do chefe, limites das células e âncora constante. Resultados de importação, integração, interação e renderização devem ser registrados no relatório de validação do Marco 4.
