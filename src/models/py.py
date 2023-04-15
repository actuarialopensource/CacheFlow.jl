

from modelx.serialize.jsonvalues import *

_formula = lambda point_id: None

_bases = []

_allow_none = None

_spaces = []

# ---------------------------------------------------------------------------
# Cells

def age(t):
    return age_at_entry() + duration(t)


def age_at_entry():
    return model_point()["age_at_entry"]


def check_pv_net_cf():

    import math
    res = sum(list(net_cf(t) for t in range(proj_len())) * disc_factors()[:proj_len()])

    return math.isclose(res, pv_net_cf())


def claim_pp(t):
    return sum_assured()


def claims(t):
    return claim_pp(t) * pols_death(t)


def commissions(t): 
    return premiums(t) if duration(t) == 0 else 0


def disc_factors():
    return np.array(list((1 + disc_rate_mth()[t])**(-t) for t in range(proj_len())))


def disc_rate_mth():
    return np.array(list((1 + disc_rate_ann[t//12])**(1/12) - 1 for t in range(proj_len())))


def duration(t):
    """Duration in force in years"""
    return t//12


def expense_acq():
    """Acquisition expense per policy

    ``300`` by default.
    """
    return 300


def expense_maint():
    return 60


def expenses(t):
    maint = pols_if(t) * expense_maint()/12 * inflation_factor(t)

    if t == 0:
        return expense_acq() + maint
    else:
        return maint


def inflation_factor(t):
    return (1 + inflation_rate)**(t/12)


def inflation_rate():
    """Inflation rate"""
    return 0.01


def lapse_rate(t):
    return max(0.1 - 0.02 * duration(t), 0.02)


def loading_prem():
    return 0.50


def model_point():
    return model_point_table.loc[point_id]


def mort_rate(t):
    return mort_table[str(max(min(5, duration(t)),0))][age(t)]


def mort_rate_mth(t):
    return 1-(1- mort_rate(t))**(1/12)


def net_cf(t):
    return premiums(t) - claims(t) - expenses(t) - commissions(t)


def net_premium_pp():
    return pv_claims() / pv_pols_if()


def policy_term():

    return model_point()["policy_term"]


def pols_death(t):
    """Number of death occurring at time t"""
    return pols_if(t) * mort_rate_mth(t)


def pols_if(t):
    if t==0:
        return pols_if_init()
    elif t > policy_term() * 12:
        return 0
    else:
        return pols_if(t-1) - pols_lapse(t-1) - pols_death(t-1) - pols_maturity(t)


def pols_if_init(): 
    return 1


def pols_lapse(t):
    return (pols_if(t) - pols_death(t)) * (1-(1 - lapse_rate(t))**(1/12))


def pols_maturity(t):
    if t == policy_term() * 12:
        return pols_if(t-1) - pols_lapse(t-1) - pols_death(t-1)
    else:
        return 0


def premium_pp():
    return round((1 + loading_prem()) * net_premium_pp(), 2)


def premiums(t):
    return premium_pp() * pols_if(t)


def proj_len():
    return 12 * policy_term() + 1


def pv_claims():
    return sum(list(claims(t) for t in range(proj_len())) * disc_factors()[:proj_len()])


def pv_commissions():
    return sum(list(commissions(t) for t in range(proj_len())) * disc_factors()[:proj_len()])


def pv_expenses():
    return sum(list(expenses(t) for t in range(proj_len())) * disc_factors()[:proj_len()])


def pv_net_cf():
    return pv_premiums() - pv_claims() - pv_expenses() - pv_commissions()


def pv_pols_if():
    return sum(list(pols_if(t) for t in range(proj_len())) * disc_factors()[:proj_len()])


def pv_premiums():
    return sum(list(premiums(t) for t in range(proj_len())) * disc_factors()[:proj_len()])


def result_cf():

    t_len = range(proj_len())

    data = {
        "Premiums": [premiums(t) for t in t_len],
        "Claims": [claims(t) for t in t_len],
        "Expenses": [expenses(t) for t in t_len],
        "Commissions": [commissions(t) for t in t_len],
        "Net Cashflow": [net_cf(t) for t in t_len]
    }
    return pd.DataFrame.from_dict(data)


def result_pv():
    cols = ["Premiums", "Claims", "Expenses", "Commissions", "Net Cashflow"]
    pvs = [pv_premiums(), pv_claims(), pv_expenses(), pv_commissions(), pv_net_cf()]
    per_prem = [x / pv_premiums() for x in pvs]

    return pd.DataFrame.from_dict(
            data={"PV": pvs, "% Premium": per_prem},
            columns=cols,
            orient='index')


def sex(): 
    return model_point()["sex"]


def sum_assured():
    return model_point()["sum_assured"]


# ---------------------------------------------------------------------------
# References

disc_rate_ann = ("DataClient", 2180220040776)

model_point_table = ("DataClient", 2180211700488)

mort_table = ("DataClient", 2180225433416)

pd = ("Module", "pandas")

point_id = 1

np = ("Module", "numpy")