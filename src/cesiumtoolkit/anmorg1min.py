from pathlib import Path
import pandas as pd
import numpy as np
from scipy.interpolate import UnivariateSpline
from tqdm import tqdm
from concurrent.futures import ProcessPoolExecutor
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)

class ANMORG1MIN:
    def __init__(self, input_dir, batch_size=100000):
        self.input_dir = Path(input_dir)
        self.batch_size = batch_size

    def process_directory(self):
        files = sorted(self.input_dir.glob("*.txt.anmorg"))
        for file_path in files:
            print(f"\nProcessing: {file_path}")
            split_dfs = self.main_processing(file_path)
            self.plot_with_plotly(split_dfs, file_path)
            self.save_processed_data(file_path, split_dfs)

    def process_batch(self, df):
        try:
            df['DateTime'] = pd.to_datetime(df[['Year', 'Month', 'Day', 'Hour', 'Minute', 'Second']])
            df.set_index('DateTime', inplace=True)
            df.drop(['Year', 'Month', 'Day', 'Hour', 'Minute', 'Second'], axis=1, inplace=True)
            df_resampled = self.resample_df(df)
            df_filtered = self.spline_filter(df_resampled)
            return df_filtered
        except Exception as e:
            print(f"Error in process_batch: {e}")
            return pd.DataFrame()

    def spline_filter(self, data, threshold=100, s=0.5):
        x = np.arange(len(data))
        y = data['Tmag'].values
        spline = UnivariateSpline(x, y, s=s)
        y_spline = spline(x)
        return data[np.abs(y - y_spline) < threshold]

    def resample_df(self, data):
        data = data.astype({'Latitude': 'float32', 'Longitude': 'float32', 'Tmag': 'float32'})
        return data.resample('1min').nearest()

    def split_df_on_gaps(self, data, gap):
        indices = np.where(np.diff(data.index) > gap)[0] + 1
        return np.split(data, indices)

    def main_processing(self, file_path):
        df = pd.read_csv(file_path, sep="\s+", header=None, 
                         names=['Year', 'Month', 'Day', 'Hour', 'Minute', 'Second', 'Latitude', 'Longitude', 'Tmag'])
        batches = [df.iloc[i*self.batch_size:(i+1)*self.batch_size] for i in range((len(df) + self.batch_size - 1) // self.batch_size)]

        resampled_dfs = []
        with ProcessPoolExecutor() as executor:
            futures = [executor.submit(self.process_batch, batch) for batch in batches]
            for future in tqdm(futures, desc="Processing Batches"):
                try:
                    result = future.result()
                    if not result.empty:
                        resampled_dfs.append(result)
                except Exception as e:
                    print(f"Error in batch processing: {e}")

        if resampled_dfs:
            combined_df = pd.concat(resampled_dfs)
            combined_df.sort_index(inplace=True)
            return self.split_df_on_gaps(combined_df, pd.Timedelta('1h'))
        else:
            return []

    def plot_with_plotly(self, split_dfs, file_path):
        if not split_dfs:
            print("No data to plot.")
            return

        fig = make_subplots(rows=2, cols=1, shared_xaxes=True, vertical_spacing=0.1,
                            subplot_titles=("Original Data", "Resampled Data"))

        combined_df = pd.concat(split_dfs)
        customdata = np.stack((combined_df['Tmag'],), axis=-1)

        fig.add_trace(
            go.Scatter(name='Original Data', mode='lines', x=split_dfs[0].index, y=split_dfs[0]['Tmag'],
                       customdata=customdata, hovertemplate='<br>'.join([
                           'Datetime: %{x}', '<b>Original</b>: %{y:.2f}', '<extra></extra>']),), row=1, col=1)

        for df in split_dfs:
            fig.add_trace(
                go.Scatter(name='Resampled Data', mode='lines', x=df.index, y=df['Tmag'],
                           customdata=customdata, hovertemplate='<br>'.join([
                               'Datetime: %{x}', '<b>Resampled</b>: %{y:.2f}', '<extra></extra>']),), row=2, col=1)

        fig.update_layout(height=600, width=1000, hovermode='x unified',
                          legend_traceorder="normal", title_text="Original and Resampled Data")
        fig.update_traces(xaxis='x2')

        output_html = file_path.with_suffix(".1min_plot.html")
        fig.write_html(str(output_html))
        print(f"Saved plot to {output_html}")

    def save_processed_data(self, file_path, split_dfs):
        print("Saving processed data...")
        for i, df_resampled in enumerate(split_dfs, start=1):
            df_resampled['Latitude'] = pd.to_numeric(df_resampled['Latitude'], errors='coerce')
            df_resampled['Longitude'] = pd.to_numeric(df_resampled['Longitude'], errors='coerce')
            df_resampled['Tmag'] = pd.to_numeric(df_resampled['Tmag'], errors='coerce')

            df_resampled['Year'] = df_resampled.index.year.map('{:4d}'.format)
            df_resampled['Month'] = df_resampled.index.month.map('{:02d}'.format)
            df_resampled['Day'] = df_resampled.index.day.map('{:02d}'.format)
            df_resampled['Hour'] = df_resampled.index.hour.map('{:02d}'.format)
            df_resampled['Minute'] = df_resampled.index.minute.map('{:02d}'.format)
            df_resampled['Second'] = df_resampled.index.second.map('{:02d}'.format)

            df_resampled['Latitude'] = df_resampled['Latitude'].map('{:2.8f}'.format)
            df_resampled['Longitude'] = df_resampled['Longitude'].map('{:3.8f}'.format)
            df_resampled['Tmag'] = df_resampled['Tmag'].map('{:5.3f}'.format)

            df_to_save = df_resampled[['Year', 'Month', 'Day', 'Hour', 'Minute', 'Second', 'Latitude', 'Longitude', 'Tmag']]
            output_filename = file_path.with_name(file_path.stem + f"_{i:02d}.1min.anmorg")
            with open(output_filename, 'w') as file:
                for row in df_to_save.itertuples(index=False, name=None):
                    file.write(' '.join(map(str, row)) + '\n')
            print(f"Saved {output_filename}")