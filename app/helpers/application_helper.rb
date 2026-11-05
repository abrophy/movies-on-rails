module ApplicationHelper
  def format_rating(value)
    number_with_precision(value.to_f, precision: 1, strip_insignificant_zeros: true)
  end

  # Renders a five-star glyph string (e.g. ★★★☆☆) for a 0..5 rating.
  def render_stars(value)
    filled = value.to_f.round.clamp(0, 5)
    ("★" * filled) + ("☆" * (5 - filled))
  end
end
