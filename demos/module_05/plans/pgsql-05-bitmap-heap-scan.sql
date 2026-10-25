select facturecd, datefacture, montantttc
from outils.m05_facture
where datefacture between date '2011-03-01' and date '2011-03-31'
