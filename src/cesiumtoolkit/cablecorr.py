import pandas as pd
from geopy.distance import geodesic
from geographiclib.geodesic import Geodesic
import matplotlib.pyplot as plt
import os
from pathlib import Path

class CABLECORRECTION:
    def __init__(self, input_dir, wire_len=329.95, steps=3):
        self.input_dir = Path(input_dir)
        self.wire_len = wire_len / 1000  # convert to kilometers
        self.steps = steps


    def get_bearing(self, lat1, lon1, lat2, lon2):
        return Geodesic.WGS84.Inverse(lat1, lon1, lat2, lon2)['azi1']

    def calculate_new_position(self, lat1, lon1, distance_km, bearing_degrees):
        origin = (lat1, lon1)
        destination = geodesic(kilometers=distance_km).destination(origin, bearing_degrees)
        return destination.latitude, destination.longitude
    
    def process_directory(self):
        for file_path in self.input_dir.glob("*.1min.anmorg"):
            df = self.process_file(file_path)
            self.plot_preview(df, file_path)


    def process_file(self, file_path):
        file_name = os.path.basename(file_path)
        print(f"Processing: {file_name}")

        df = pd.read_csv(file_path, sep="\s+", header=None)
        df.columns = ['Year', 'Month', 'Day', 'Hour', 'Minute', 'Second', 'Latitude', 'Longitude', 'Tmag']
        df['DateTime'] = pd.to_datetime(df[['Year', 'Month', 'Day', 'Hour', 'Minute', 'Second']])
        df.set_index('DateTime', inplace=True)

        df['Lat1'] = df['Latitude'].shift(-1 * self.steps)
        df['Lon1'] = df['Longitude'].shift(-1 * self.steps)

        for index, row in df.iterrows():
            if not pd.isna(row['Lat1']) and not pd.isna(row['Lon1']):
                bearing = self.get_bearing(row['Latitude'], row['Longitude'], row['Lat1'], row['Lon1'])
                if not pd.isna(bearing):
                    new_lat, new_lon = self.calculate_new_position(
                        row['Latitude'], row['Longitude'], self.wire_len, (bearing + 180) % 360)
                    df.at[index, 'Lat3'] = new_lat
                    df.at[index, 'Lon3'] = new_lon

        df.dropna(subset=['Lat1', 'Lon1'], inplace=True)
        df.drop(['Lat1', 'Lon1'], axis=1, inplace=True)

        new_df = df.copy().reset_index()
        new_df['Year'] = new_df['DateTime'].dt.year
        new_df['Month'] = new_df['DateTime'].dt.month
        new_df['Day'] = new_df['DateTime'].dt.day
        new_df['Hour'] = new_df['DateTime'].dt.hour
        new_df['Minute'] = new_df['DateTime'].dt.minute
        new_df['Second'] = new_df['DateTime'].dt.second

        new_df['Latitude'] = new_df['Lat3']
        new_df['Longitude'] = new_df['Lon3']

        new_df['Latitude'] = new_df['Latitude'].map('{:2.8f}'.format)
        new_df['Longitude'] = new_df['Longitude'].map('{:3.8f}'.format)
        new_df['Tmag'] = new_df['Tmag'].map('{:5.3f}'.format)

        for col in ['Year', 'Month', 'Day', 'Hour', 'Minute', 'Second']:
            new_df[col] = new_df[col].map(lambda x: f"{x:02d}" if col != 'Year' else f"{x:4d}")

        new_df.drop(['DateTime', 'Lat3', 'Lon3'], axis=1, inplace=True)

        output_filename = file_path.with_suffix('.anmorg.anm_cc')
        new_df.to_csv(output_filename, sep=' ', index=False, header=False)
        print(f"Saved to: {output_filename}")

        return df  # return original df with Lat3/Lon3 for optional plotting

    def plot_preview(self, df, file_name, n=20, outdir=None):
        df_subset = df.iloc[:n]

        plt.figure(figsize=(10, 8))
        plt.title(f"Cable Corr; {file_name}")
        plt.xlabel('Longitude')
        plt.ylabel('Latitude')
        plt.scatter(df_subset['Longitude'], df_subset['Latitude'], c='blue', label='Original', s=80)
        plt.scatter(df_subset['Lon3'], df_subset['Lat3'], c='red', label='Modified', s=10)
        plt.legend()
        plt.grid(True)
        plt.axis('equal')

        if outdir is None:
            outdir = Path(file_name).parent
        else:
            outdir = Path(outdir)
            outdir.mkdir(exist_ok=True, parents=True)

        output_path = outdir / f"{Path(file_name).stem}.cablecorr.png"
        plt.savefig(output_path, dpi=300)
        plt.close()
        print(f"Saved preview plot to: {output_path}")
