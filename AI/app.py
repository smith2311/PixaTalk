import tkinter as tk
import customtkinter as ctk
from PIL import ImageTk, Image
import torch
from diffusers import StableDiffusionPipeline, StableDiffusionUpscalePipeline
import os
from authtoken import auth_token

# App setup
app = tk.Tk()
app.geometry("532x622")
app.title("Aquarius 4K")
ctk.set_appearance_mode("dark")

# Prompt entry field
prompt = ctk.CTkEntry(master=app,
                      height=40,
                      width=512,
                      font=("Arial", 20),
                      text_color="black",
                      fg_color="white",
                      placeholder_text="Enter your prompt here")
prompt.place(x=10, y=10)

# Output image label
lmain = ctk.CTkLabel(master=app, height=512, width=512, text="")
lmain.place(x=10, y=110)

# Model setup
device = "cpu"  # Change to "cuda" if you have GPU
base_model_id = "CompVis/stable-diffusion-v1-4"
upscale_model_id = "stabilityai/stable-diffusion-x4-upscaler"

# Load base text-to-image pipeline
pipe = StableDiffusionPipeline.from_pretrained(
    base_model_id,
    torch_dtype=torch.float32,
    use_safetensors=True,
    token=auth_token
).to(device)

# Load upscaler pipeline
upscaler = StableDiffusionUpscalePipeline.from_pretrained(
    upscale_model_id,
    revision="fp32",
    torch_dtype=torch.float32,
    token=auth_token
).to(device)

# Image generation function
def generate():
    try:
        text_prompt = prompt.get().strip()
        if not text_prompt:
            lmain.configure(text="Please enter a prompt.")
            return

        # Step 1: Generate base image
        base_image = pipe(text_prompt, guidance_scale=8.5).images[0]

        # Step 2: Upscale image to 2048x2048
        upscaled_image = upscaler(prompt=text_prompt, image=base_image).images[0]

        # Step 3: Resize to exact 4K (3840x2160)
        final_image = upscaled_image.resize((3840, 2160))

        # Step 4: Save with unique filename
        existing_files = [f for f in os.listdir() if f.startswith("AQ_") and f.endswith(".png")]
        numbers = [int(f.split("_")[1].split(".")[0]) for f in existing_files if f.split("_")[1].split(".")[0].isdigit()]
        next_number = max(numbers) + 1 if numbers else 1
        filename = f"AQ_{next_number:04}.png"
        final_image.save(filename)

        # Step 5: Show thumbnail preview in Tkinter
        preview = final_image.resize((512, 512))
        photo = ImageTk.PhotoImage(preview)
        lmain.configure(image=photo, text="")
        lmain.image = photo

    except Exception as e:
        lmain.configure(text=f"Error: {str(e)}")

# Generate button
trigger = ctk.CTkButton(master=app,
                        height=40,
                        width=120,
                        font=("Arial", 20),
                        text_color="white",
                        fg_color="blue",
                        text="Generate",
                        command=generate)
trigger.place(x=206, y=60)

app.mainloop()
