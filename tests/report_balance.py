"""Summarize engine events; never select or change match outcomes."""
import json
from pathlib import Path
from statistics import mean

ROOT = Path(__file__).resolve().parents[1]


def main():
    payload = json.loads((ROOT / "docs/balanceamento_marco5.json").read_text())
    rows = payload["matches"]
    wins = sum(r["result"] == "BOSS DEFEATED" for r in rows)
    losses = sum(r["result"] == "GRUPO DERROTADO" for r in rows)
    lines = ["# Balanceamento — Marco 5", "", "## Método", "",
        f"Executadas {len(rows)} partidas no Godot {payload['godot']}: doze políticas × sementes 17, 42 e 99. "
        "O simulador usa a IA de produção, a ordem de iniciativa e os recursos reais. Não modifica HP, recargas, "
        "dano ou resultado e não força vitórias ou derrotas. Limite de segurança: 80 rodadas e 1.800 eventos de decisão por partida.", "",
        "As políticas consultam a percepção real e mantêm somente a última posição observada do inimigo oculto. "
        "A janela de meteoros é decidida antes de qualquer ação ou passagem de turno. Evasão gasta a ação disponível e, quando ocorre fora do turno, reserva a principal do próximo turno; "
        "defesa gasta bônus e PM; nenhuma resposta concede turno completo ou renova recursos.", "",
        "| Estratégia | V | D | Rodadas | HP heróis médio | Dano chefe | Dano lacaios | Invocações | Fumaças | Chuvas | Quedas | Alvos | Evasões/ações | Defesas | Escudos | Auras | Dano aura | Dano piso |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|"]
    for policy in payload["policies"]:
        selected = [r for r in rows if r["strategy"] == policy]
        values = [policy, str(sum(r["result"] == "BOSS DEFEATED" for r in selected)),
                  str(sum(r["result"] == "GRUPO DERROTADO" for r in selected)),
                  f"{min(r['rounds'] for r in selected)}–{max(r['rounds'] for r in selected)}",
                  f"{mean(sum(r['hero_hp']) for r in selected):.1f}"]
        values += [str(sum(r[key] for r in selected)) for key in ["boss_damage", "minion_damage", "summons", "smoke", "meteors", "meteor_impacts", "meteor_hits", "evades", "guards", "shield", "aura", "aura_damage", "floor_damage"]]
        lines.append("| " + " | ".join(values) + " |")
    lines += ["", f"Agregado: **{wins} vitórias, {losses} derrotas, {len(rows)-wins-losses} limites de segurança**.", "",
        "As colunas de dano e usos somam as três sementes; apenas HP final é média. Chuvas contam a habilidade principal; quedas incluem os meteoros das reações; alvos contam eventos de dano por meteoros, "
        "não a quantidade de animações. Cada evasão corresponde a uma ação principal sacrificada. O JSON registra HP individual, "
        "dano de retaliação do escudo, ações, reações, fase e contagem de cada habilidade utilizada pelos heróis.", "",
        "## Políticas", "",
        "Agressiva: prioriza dano. Defensiva: defesa, controle e proteção de meteoro. Cura: recupera aliados cedo. "
        "Antimagia: dissipa fumaça/escudo. Lacaios: elimina magos primeiro. Ignorar lacaios: concentra no rei. "
        "Mau posicionamento: aproxima conjuradores e ignora riscos. Evasão inteligente: sai de áreas anunciadas preservando distância. "
        "Evasão excessiva: gasta a ação sempre que pode escapar. Ignorar meteoros: permanece sob marcas. "
        "Corpo a corpo: concentra os heróis junto ao chefe. Explorar fumaça: tenta ataques de área na última posição observada.", "",
        "## Reprodução", "", "```bash", "godot --path . --headless --script tests/test_encounters.gd", "python tests/report_balance.py", "```", "",
        "## Limites da evidência", "",
        "Na política defensiva, Silêncio pode impedir legitimamente a invocação inicial enquanto durar o controle. A IA mantém a prioridade pendente para a primeira oportunidade permitida. A interpretação não atribui ausência de invocação por silêncio a falha de prioridade.", "",
        "Três sementes por política são uma amostra exploratória; não estimam taxa de vitória de jogadores humanos. "
        "Os bots conhecem habilidades e não representam descoberta inicial. Dano é a soma nominal dos eventos (pode incluir excesso "
        "no golpe fatal); custo de HP da Fushigiri não conta como dano inimigo. Queimaduras e ambiente entram no dano do chefe "
        "e também nas métricas específicas, quando identificadas pela causa. Testes isolados cobrem interações que estas políticas não exercitam.", ""]
    if wins == len(rows):
        lines += ["**Dificuldade ainda permissiva:** todas as políticas venceram. A amostra não comprova punição suficiente de decisões ruins. "
                  "Aumentar HP ou adulterar estratégias para fabricar derrotas não foi usado como solução.", ""]
    elif losses == len(rows):
        lines += ["**Dificuldade excessiva nesta amostra:** todas as políticas perderam. Estes resultados não comprovam vitória acessível "
                  "com os recursos e decisões do bot; a leitura deve orientar ajustes, não ser ocultada.", ""]
    missing = [label for key,label in [("summons","invocação"),("smoke","fumaça"),("meteors","meteoros"),("shield","escudo"),("aura","aura")] if sum(r[key] for r in rows) == 0]
    if missing:
        lines += ["Habilidades ausentes do lote: " + ", ".join(missing) + ". Teste funcional isolado não substitui cobertura contextual da IA.", ""]
    (ROOT / "docs/BALANCEAMENTO_MARCO5.md").write_text("\n".join(lines))


if __name__ == "__main__":
    main()
