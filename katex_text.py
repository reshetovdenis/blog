import matplotlib.pyplot as plt
import matplotlib as mpl

# Configure matplotlib to use LaTeX
mpl.rcParams['text.usetex'] = True
mpl.rcParams['text.latex.preamble'] = r'\usepackage{amsmath}'

def render_katex_to_image(katex_text, output_file):
    # Wrap the KaTeX text in math mode
    wrapped_text = f"${katex_text}$"
    
    # Create a new figure
    fig, ax = plt.subplots()
    ax.text(0.5, 0.5, wrapped_text, horizontalalignment='center', verticalalignment='center', fontsize=20)
    ax.axis('off')
    
    # Save the figure as an image file
    plt.savefig(output_file, bbox_inches='tight')
    plt.close(fig)

# Example usage
katex_text = r"\frac{a}{b} = \sqrt{c^2 + d^2}"
output_file = "katex_output.png"
render_katex_to_image(katex_text, output_file)