# Balanceamento — Marco 5

## Método

Executadas 36 partidas no Godot 4.7.2-stable (official): doze políticas × sementes 17, 42 e 99. O simulador usa a IA de produção, a ordem de iniciativa e os recursos reais. Não modifica HP, recargas, dano ou resultado e não força vitórias ou derrotas. Limite de segurança: 80 rodadas e 1.800 eventos de decisão por partida.

As políticas consultam a percepção real e mantêm somente a última posição observada do inimigo oculto. A janela de meteoros é decidida antes de qualquer ação ou passagem de turno. Evasão gasta a ação disponível e, quando ocorre fora do turno, reserva a principal do próximo turno; defesa gasta bônus e PM; nenhuma resposta concede turno completo ou renova recursos.

| Estratégia | V | D | Rodadas | HP heróis médio | Dano chefe | Dano lacaios | Invocações | Fumaças | Chuvas | Quedas | Alvos | Evasões/ações | Defesas | Escudos | Auras | Dano aura | Dano piso |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| agressivo | 3 | 0 | 6–8 | 167.0 | 843 | 203 | 6 | 4 | 0 | 31 | 31 | 0 | 9 | 3 | 4 | 60 | 24 |
| defensivo | 3 | 0 | 7–7 | 447.0 | 531 | 0 | 0 | 0 | 0 | 21 | 18 | 3 | 7 | 0 | 0 | 0 | 32 |
| cura | 3 | 0 | 7–12 | 271.3 | 1355 | 183 | 4 | 4 | 3 | 45 | 39 | 11 | 0 | 5 | 6 | 107 | 99 |
| antimagia | 1 | 2 | 12–16 | 18.3 | 1435 | 606 | 6 | 12 | 3 | 59 | 42 | 18 | 0 | 12 | 11 | 13 | 97 |
| lacaios | 3 | 0 | 7–7 | 407.0 | 747 | 42 | 3 | 2 | 0 | 29 | 22 | 7 | 0 | 4 | 4 | 130 | 48 |
| ignora_lacaios | 3 | 0 | 6–7 | 202.3 | 839 | 91 | 3 | 1 | 0 | 29 | 29 | 0 | 0 | 3 | 3 | 66 | 23 |
| mau_posicionamento | 2 | 1 | 5–6 | 41.7 | 1331 | 91 | 3 | 2 | 1 | 29 | 30 | 0 | 0 | 3 | 6 | 340 | 158 |
| evita_meteoros | 2 | 1 | 9–14 | 73.7 | 1273 | 444 | 5 | 8 | 3 | 56 | 45 | 12 | 11 | 11 | 9 | 0 | 93 |
| enfrenta_fumaca | 3 | 0 | 6–7 | 205.0 | 820 | 126 | 4 | 4 | 0 | 31 | 31 | 0 | 0 | 3 | 4 | 66 | 47 |
| evasao_excessiva | 0 | 3 | 10–12 | 0.0 | 1642 | 640 | 6 | 8 | 4 | 52 | 37 | 21 | 0 | 7 | 7 | 150 | 205 |
| ignora_meteoros | 3 | 0 | 6–7 | 202.3 | 839 | 91 | 3 | 1 | 0 | 29 | 29 | 0 | 0 | 3 | 3 | 66 | 23 |
| corpo_a_corpo | 3 | 0 | 6–6 | 357.7 | 891 | 91 | 3 | 1 | 0 | 24 | 24 | 0 | 0 | 3 | 5 | 175 | 102 |

Agregado: **29 vitórias, 7 derrotas, 0 limites de segurança**.

As colunas de dano e usos somam as três sementes; apenas HP final é média. Chuvas contam a habilidade principal; quedas incluem os meteoros das reações; alvos contam eventos de dano por meteoros, não a quantidade de animações. Cada evasão corresponde a uma ação principal sacrificada. O JSON registra HP individual, dano de retaliação do escudo, ações, reações, fase e contagem de cada habilidade utilizada pelos heróis.

## Políticas

Agressiva: prioriza dano. Defensiva: defesa, controle e proteção de meteoro. Cura: recupera aliados cedo. Antimagia: dissipa fumaça/escudo. Lacaios: elimina magos primeiro. Ignorar lacaios: concentra no rei. Mau posicionamento: aproxima conjuradores e ignora riscos. Evasão inteligente: sai de áreas anunciadas preservando distância. Evasão excessiva: gasta a ação sempre que pode escapar. Ignorar meteoros: permanece sob marcas. Corpo a corpo: concentra os heróis junto ao chefe. Explorar fumaça: tenta ataques de área na última posição observada.

## Reprodução

```bash
godot --path . --headless --script tests/test_encounters.gd
python tests/report_balance.py
```

## Limites da evidência

Na política defensiva, Silêncio pode impedir legitimamente a invocação inicial enquanto durar o controle. A IA mantém a prioridade pendente para a primeira oportunidade permitida. A interpretação não atribui ausência de invocação por silêncio a falha de prioridade.

Três sementes por política são uma amostra exploratória; não estimam taxa de vitória de jogadores humanos. Os bots conhecem habilidades e não representam descoberta inicial. Dano é a soma nominal dos eventos (pode incluir excesso no golpe fatal); custo de HP da Fushigiri não conta como dano inimigo. Queimaduras e ambiente entram no dano do chefe e também nas métricas específicas, quando identificadas pela causa. Testes isolados cobrem interações que estas políticas não exercitam.
