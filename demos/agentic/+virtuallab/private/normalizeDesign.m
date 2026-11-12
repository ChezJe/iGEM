function values = normalizeDesign(rows)
    values = [(rows.PromoterStrength-0.25)/2.75, rows.InducerMicromolar/100];
end
