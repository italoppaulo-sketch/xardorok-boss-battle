# Nova gameplay — demonstração da fumaça

A gravação anterior foi reproduzida com a política agressiva e seed 42. Houve quatro ataques de heróis enquanto existia fumaça. Nos quatro, `visible()` retornou verdadeiro: os pontos de origem e destino estavam dentro da mesma nuvem. Isso corresponde à exceção existente em `Perception.presentation_line()`, utilizada também pela linha de visão de combate. Não foi identificado ataque direto atravessando a borda da fumaça nesse replay.

A nova gravação usa uma política conservadora exclusiva do teste: nenhuma habilidade ofensiva dos heróis é executada enquanto houver uma nuvem ativa. Cassandra prioriza Antimagia sobre a região da nuvem; os ataques só voltam depois da dissipação. A cena faz uma pausa de 2,5 segundos antes da decisão de um herói sob fumaça, para tornar a situação legível no vídeo.

Nenhuma regra do jogo foi alterada: HP, recursos, iniciativa, IA inimiga, dano, visibilidade, câmera, arena e sprites permanecem iguais. Isso demonstra uma tática diferente; não introduz uma regra nova que proíba combate entre personagens dentro da mesma nuvem. A exceção de visão compartilhada e a Flecha de Gelo dirigida ao chão permanecem disponíveis no jogo.

## Validação executada

- Godot 4.7.2 oficial, compatibilidade OpenGL/Mesa.
- Regressão de regras (`test_marco4.gd`): 411 verificações, zero falhas. Regressão de visibilidade (`test_visibility_marco5.gd`): 46 verificações, zero falhas; cobre ocultação ao entrar/sair, posições desenhadas, remoção da fumaça e paredes que continuam bloqueando ataques.
- Duas partidas completas em teste sem interface: política anterior e política conservadora, ambas seed 42. Vitória na rodada 6 e na rodada 7, respectivamente.
- Nova política: uma conjuração de fumaça, uma nuvem dissipada por Cassandra, zero ataques ofensivos de heróis com fumaça ativa e zero ataques diretos sem linha de visão. Zero falhas no teste. Resultados em `smoke_policy_validation.json`.
- Captura audiovisual real da cena de produção por `capture_smoke_marco6.gd`; auditoria das ações e áudio em `capture_smoke_executed.json`. Sem alterações artificiais de HP, recursos ou RNG durante a partida.
- Captura concluída: vitória na rodada 7, 377 cues, zero falhas. 4.102 frames a 30 FPS, duração de 136,73 segundos. Fumaça por volta de **01:35**, Antimagia por volta de **01:39**, coroa e fanfarra por volta de **02:09**. A auditoria da partida gravada confirmou uma nuvem dissipada e zero ataques ofensivos dos heróis enquanto havia fumaça ativa.

## Reprodução

```sh
godot --headless --path . --script tests/test_smoke_capture.gd
godot --path . --rendering-method gl_compatibility --write-movie gameplay_fumaca.avi --fixed-fps 30 --script tests/capture_smoke_marco6.gd
```

O vídeo é uma partida automatizada, não uma sessão controlada manualmente. O bot de demonstração está em `tests/support/smoke_capture_strategy.gd`; não é a IA de produção. Os testes gerais do Marco 6 não foram repetidos nesta revisão, que acrescenta somente testes e documentação.
