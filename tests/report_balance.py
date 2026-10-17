"""Summarize engine-emitted metrics without selecting or changing match outcomes."""
import json
from pathlib import Path
import statistics

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "docs/balanceamento_marco4.json"

def main():
    payload = json.loads(DATA.read_text())
    rows = payload["matches"]
    lines = ["# Balanceamento — Marco 4", "", "## Execução", "",
        f"Executadas {len(rows)} partidas no {payload['godot']}, com nove políticas e sementes 17, 42 e 99. "
        "O simulador não altera HP, recursos, iniciativa, recargas ou resultados. A aleatoriedade usa o RNG real do motor. "
        "As políticas conhecem apenas unidades percebidas e posições anteriormente observadas; nenhuma persegue a posição atual de inimigo oculto.",
        "", "| Estratégia | Vitórias | Derrotas | Rodadas mín–máx | HP heróis ao fim, média | Dano chefe, média | Físicos | Meteoros | Fumaças | Invocações | Reações | Fase 2 |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|"]
    for policy in payload["policies"]:
        matches = [r for r in rows if r["strategy"] == policy]
        wins = sum(r["result"] == "BOSS DEFEATED" for r in matches)
        losses = sum(r["result"] == "GRUPO DERROTADO" for r in matches)
        rounds = [r["rounds"] for r in matches]
        values = [policy, str(wins), str(losses), f"{min(rounds)}–{max(rounds)}",
                  f"{statistics.mean(sum(r['hero_hp']) for r in matches):.1f}",
                  f"{statistics.mean(r['boss_damage'] for r in matches):.1f}"]
        values += [str(sum(r[k] for r in matches)) for k in ["physical", "meteors", "smoke", "summons", "reactions", "phase_two"]]
        lines.append("| " + " | ".join(values) + " |")
    wins = sum(r["result"] == "BOSS DEFEATED" for r in rows)
    losses = sum(r["result"] == "GRUPO DERROTADO" for r in rows)
    limits = len(rows)-wins-losses
    lines += ["", f"Resultado agregado: {wins} vitórias, {losses} derrotas, {limits} partidas no limite de segurança. "
        "As colunas de habilidades e reações somam os três ensaios de cada estratégia. "
        "O JSON conserva rodadas, resultado, HP individual restante, dano por lacaios, ações e contagem completa de habilidades de cada partida.",
        "", "## Como reproduzir", "", "```bash", "godot --path . --headless --script tests/test_encounters.gd", "python tests/report_balance.py", "```", "",
        "Cada partida começa nas posições originais. Só o combatente ativo pode agir; inimigos usam a IA de produção. "
        "O limite é de 80 rodadas. Todas as operações verificam HP/PM, recursos não negativos, piso válido, ocupação e limite de lacaios. "
        "As políticas são agressiva, defensiva (controle/defesa), cura prioritária, Antimagia prioritária, foco em lacaios, ignorar lacaios, "
        "mau posicionamento (aproxima conjuradores), evasão de meteoros e enfrentamento da fumaça por área.",
        "", "## Interpretação e limitações", "",
        "Três sementes por política constituem uma comparação exploratória, não uma estimativa estatística para jogadores humanos. "
        "Estas heurísticas conhecem o catálogo e escolhem habilidades de dano elevadas; não representam um jogador descobrindo o jogo. "
        "Dano nominal é a soma dos eventos do motor e pode incluir excesso no golpe fatal. O dano ambiental e queimaduras contam para o chefe; "
        "o custo de HP da Fushigiri fica separado. Ações incluem bônus e ações principais registrados como conjuração; movimentos não contam.", "",
        "As decisões do bot não foram alteradas para provocar derrotas nem os parâmetros modificados entre sementes. "
        "A estratégia defensiva utiliza Silêncio, suprimindo legitimamente magias e reações. O raio encadeado pode eliminar acólitos antes da entrada deles na iniciativa. "
        "Os testes funcionais isolados validam também magias que não aparecem nas partidas simuladas.", ""]
    if wins == len(rows):
        lines += ["**Limitação de dificuldade:** todas as políticas testadas venceram. O ensaio demonstra que a batalha é vencível, "
                  "mas não comprova dificuldade de chefe final nem punição suficiente de posicionamento ruim. Ajustes futuros devem ser validados "
                  "com jogadores e novas sementes, mantendo estes resultados como evidência em vez de prometer balanceamento definitivo.", ""]
    zero = [label for key,label in [("physical","ataque físico"),("meteors","Chuva de Meteoros"),("smoke","fumaça"),("summons","invocação")] if sum(r[key] for r in rows) == 0]
    if zero:
        lines += ["Habilidades ausentes deste lote: " + ", ".join(zero) + ". A ausência é uma limitação da cobertura contextual das partidas e da prioridade da IA; testes isolados não substituem essa observação.", ""]
    (ROOT / "docs/BALANCEAMENTO_MARCO4.md").write_text("\n".join(lines))

if __name__ == "__main__":
    main()
