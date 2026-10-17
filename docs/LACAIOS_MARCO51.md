# Marco 5.1 — diagnóstico e correção dos lacaios

## Reprodução executada antes da correção

Godot **4.7.2.stable.official.ed1daf0bf**, teste `tests/test_minions_marco51.gd`.

Cenário: Xardorok em `(7,5)`, um acólito em `(7,4)` e outro em `(8,5)`.
O modelo retornava corretamente o acólito para `(7,4)` e seu nó permanecia visível. Porém, clicar nos pés dele selecionava Xardorok: o corpo opaco do chefe se projetava sobre a célula de trás e era consultado primeiro. Resultado anterior: **4 verificações, 1 falha**.

A inspeção diferenciou os problemas:

- **Ocupação lógica:** a invocação já rejeita células ocupadas, obstáculos e posições externas ao piso. O movimento também rejeita destinos ocupados. Não foi reproduzida duplicidade de ocupação.
- **Interseção visual:** o chefe tem aproximadamente 84 pixels de largura em repouso, para células de 50 pixels. Sprites adjacentes podem se interceptar naturalmente na projeção 2D, especialmente atrás do chefe. Isso não significa ocupação da mesma célula.
- **Seleção:** a prioridade exclusiva pelo corpo opaco tornava difícil selecionar uma unidade atrás do chefe mesmo clicando em sua própria base. Esta falha foi reproduzida e corrigida.

## Correção incremental

1. A região pequena dos pés tem prioridade sobre corpos de células vizinhas: elipse de **11 × 7 pixels de raio**, sem crescimento pelo tamanho do chefe, forma gigante ou voo.
2. Fora dessa base, o clique continua usando a transparência do **quadro atual** da animação. Transparências não se tornam alvos invisíveis.
3. Empates de profundidade do cenário 2D seguem a ordem efetiva dos nós irmãos no Y-sort, mantendo desenho e seleção coerentes.
4. Marcas discretas identificam os pés no overlay. Não há ocultação de personagens, deslocamento artificial ou aumento da ocupação lógica.
5. A origem do sprite é calculada a partir dos metadados aprovados: centro do quadro menos âncora `(56,118)`. O resultado continua exatamente `(0,-54)`; isso documenta e assegura o alinhamento original sem alterar os atlas.
6. Fumaça e morte continuam desabilitando seleção da base e do corpo. A apresentação continua usando um nó independente por combatente.

Não foram modificados os PNGs ou recursos SpriteFrames aprovados, as regras de invocação, a inteligência artificial, dano, alcance ou balanceamento. O motor de combate permanece único.

## Testes executados

Comando: `Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script tests/test_minions_marco51.gd`

**86 verificações, 0 falhas**, cobrindo:

- Regressão exata do clique sobre o acólito atrás do chefe.
- Seleção das bases do chefe e de múltiplos acólitos agrupados, em quatro configurações.
- Origem dos oito atores e rejeição de regiões transparentes.
- Invocações com vizinhança ocupada, expansão da busca, limites do mapa, obstáculos e limite de três acólitos.
- Unicidade das células ocupadas e rejeição de movimento para herói ou chefe.
- Movimento real entre unidades, visibilidade durante interpolação, identidade do nó, posição final e seleção após movimento.
- Ocultação e seleção bloqueada pela fumaça legítima.

Regressões executadas separadamente: `test_visibility_marco5.gd` (**46 verificações, 0 falhas**) e `test_input.gd` (**28 verificações, 0 falhas**).

Os testes de ângulos e zoom da representação híbrida pertencem à validação da câmera. Esta correção independente foi validada primeiro na apresentação 2D original.

## Limite visual intencional

Não é possível impedir toda interseção de silhuetas de sprites altos em projeção sem afastar unidades, reduzir sprites aprovados ou alterar regras. O comportamento correto conserva a posição verdadeira, a oclusão por profundidade e meios precisos de seleção. A câmera orbital fornece observação alternativa para agrupamentos; os retratos continuam disponíveis para selecionar heróis.
