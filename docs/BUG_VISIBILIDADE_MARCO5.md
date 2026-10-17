# Desaparecimento de combatentes — diagnóstico e regressão

## Reprodução executada antes da correção

No código publicado do Marco 4, em Godot **4.7.2.stable.official.ed1daf0bf**, sem fumaça:

1. Kodokami ativo em `(4,3)`; Grosso em `(4,1)`.
2. Mover Kodokami, pela navegação real, até `(2,1)`.
3. O movimento é válido e aproxima o grupo da coluna bloqueadora em `(3,1)`.
4. Grosso fica com `actor.visible == false`, apesar de continuar vivo e na mesma posição.
5. Mudar o observador para Thomas torna Grosso visível novamente.

O teste inicial executou seis verificações e falhou em duas: visibilidade pública de Grosso e visibilidade efetiva de seu nó. Após a correção, as mesmas seis passaram.

## Causa comprovada

`arena.visible_to_player()` reutilizava `Perception.line()` para decidir se desenhava o sprite, o nome e a barra. Esse método verifica tanto fumaça quanto interseções com paredes. A linha entre o herói ativo e o aliado atravessava o volume lógico da coluna; por isso o jogo ocultava o aliado inteiro. Trocar o turno alterava `battle.observer_index()` e desfazia o efeito.

Os nós não eram compartilhados e o Y-sort não removia sprites. A reprodução isola uma atribuição explícita de `visible=false`; sobreposição natural não explica esse estado.

## Correção

- `Perception.presentation_line(a,b,smoke)` define a ocultação da apresentação por fumaça. Paredes continuam produzindo oclusão normal por Y-sort, sem apagar combatentes inteiros.
- `Perception.line(a,b,smoke,walls)` conserva a linha de visão estrita das habilidades e da IA. Ver um sprite por cima de uma ruína não permite atacá-lo através dela.
- A apresentação usa coordenadas interpoladas de todos os atores do mesmo frame, em vez da célula lógica final ou do último waypoint.
- O movimento consome o orçamento completo de distância do frame, atravessando quantos waypoints forem necessários. A interface só é liberada quando o trajeto termina. Isso remove inconsistências adicionais em quedas de FPS.
- A fumaça permanece ativa: entrar revela combatentes na mesma nuvem; sair volta a ocultá-los; dissipar restaura a apresentação imediatamente.

## Cobertura

`tests/test_visibility_marco5.gd` exercita movimento real junto a coluna, aproximação de aliados, caminhos nos dois sentidos, deltas de 0,016 a 1,4 segundo, movimento lento, voo sobre obstáculo, identidade independente dos nós, posições visuais, preservação de ações e HP, fumaça durante interpolação e limpeza ao reiniciar.

Os números definitivos e a execução integrada constam em `VALIDACAO_MARCO5.md`. Esta reprodução comprova uma causa suficiente para o sintoma relatado; não presume identificar outros casos que não tenham sido reproduzidos.
